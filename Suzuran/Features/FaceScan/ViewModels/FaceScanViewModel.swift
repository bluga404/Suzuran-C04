import AVFoundation
import Combine
import CoreImage
import SwiftUI
import UIKit
import Vision

/// Single orchestrator for the face scan lifecycle.
/// Manages camera session, face detection, validation, capture state machine,
/// ML inference dispatch, and result mapping.
@MainActor
final class FaceScanViewModel: NSObject, ObservableObject {

    // MARK: - Published State

    @Published private(set) var phase: FaceScanPhase = .requestingPermission
    @Published private(set) var readiness: FaceScanReadiness = .searchingFace
    @Published private(set) var holdProgress: Double = 0.0
    @Published private(set) var currentAngleTarget: FaceZone = .front
    @Published private(set) var scanInstruction: String = ""
    @Published private(set) var completedAngles: Int = 0

    // MARK: - Dependencies (injected)

    private let acneDetectionService: AcneDetectionService

    // MARK: - Camera

    let captureSession: AVCaptureSession

    // MARK: - Internal State

    private var previousFrameData: FaceFrameData?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoProcessingQueue = DispatchQueue(
        label: "suzuran.facescan.video",
        qos: .userInteractive
    )

    // MARK: - Hold-to-Capture State

    /// When the face first became stable + pose-matched
    private var holdStartTime: Date?
    /// Stored JPEG image data per captured angle
    private(set) var capturedImages: [FaceZone: Data] = [:]
    /// Reference to the most recent sample buffer for capture
    private var lastSampleBuffer: CMSampleBuffer?
    /// Duration (seconds) the face must be held steady before capture
    private let holdDuration: TimeInterval = 0.5
    /// JPEG compression quality per requirement 9.5
    private let jpegCompressionQuality: CGFloat = 0.82
    /// Ordered sequence of angles to capture
    private let angleSequence: [FaceZone] = [.front, .leftAngle, .rightAngle]

    // MARK: - Initialization

    init(acneDetectionService: AcneDetectionService) {
        self.acneDetectionService = acneDetectionService
        self.captureSession = AVCaptureSession()
        super.init()
        self.scanInstruction = currentAngleTarget.instruction
    }

    // MARK: - Public API

    /// Requests camera permission, configures the capture session, and starts running.
    /// Checks model readiness before proceeding — fails fast if model not loaded.
    func startScan() {
        Task {
            // Fail fast if the ML model failed to load (Requirement 8.2)
            guard acneDetectionService.isModelLoaded else {
                phase = .error(message: "Model AI gagal dimuat")
                return
            }

            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                configureCaptureSession()
                startSession()
                phase = .scanning
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted {
                    configureCaptureSession()
                    startSession()
                    phase = .scanning
                } else {
                    phase = .permissionDenied
                }
            case .denied, .restricted:
                phase = .permissionDenied
            @unknown default:
                phase = .permissionDenied
            }
        }
    }

    /// Stops the capture session.
    func stopScan() {
        stopSession()
    }

    /// Resets scan state and restarts from the first angle.
    /// Full state reset per Property 9 — resets ALL scan state.
    func retry() {
        currentAngleTarget = .front
        holdProgress = 0.0
        completedAngles = 0
        previousFrameData = nil
        capturedImages = [:]
        holdStartTime = nil
        lastSampleBuffer = nil
        readiness = .searchingFace
        scanInstruction = currentAngleTarget.instruction
        phase = .scanning
        // If session was already configured, just restart it
        if isSessionConfigured {
            startSession()
        } else {
            configureCaptureSession()
            startSession()
        }
    }

    // MARK: - View Lifecycle

    /// Called from the view's `onAppear`. Starts the scan flow.
    /// Handles initial camera permission request and session startup.
    func onViewAppear() {
        startScan()
    }

    /// Called from the view's `onDisappear`. Stops the camera session
    /// and releases resources (Requirement 8.4, 9.4).
    func onViewDisappear() {
        stopScan()
    }

    // MARK: - Camera Session Configuration

    private var isSessionConfigured = false

    private func configureCaptureSession() {
        guard !isSessionConfigured else { return }
        isSessionConfigured = true

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .high

        // Add front camera input
        guard let frontCamera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {
            phase = .error(message: "Kamera depan tidak ditemukan")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            phase = .error(message: "Gagal mengakses kamera: \(error.localizedDescription)")
            return
        }

        // Configure video output — drop late frames to prevent buffer backpressure
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoProcessingQueue)

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Configure the video data output connection for portrait orientation.
        // On iOS 17+, videoRotationAngle on data output connections reliably rotates
        // the pixel buffer data itself, so downstream code can treat it as .up orientation.
        if let connection = videoOutput.connection(with: .video) {
            // Rotate buffer to portrait (90° from landscape sensor)
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            // Mirror for front camera (selfie-style)
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
    }

    private func startSession() {
        videoProcessingQueue.async { [weak self] in
            guard let self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    private func stopSession() {
        videoProcessingQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    // MARK: - Face Detection Handlers (MainActor)

    /// Called when no face is detected in the current frame.
    private func handleNoFaceDetected() {
        readiness = .searchingFace
        scanInstruction = FaceScanReadiness.searchingFace.message
        previousFrameData = nil
        resetHoldState()
    }

    /// Called when a face is detected — validates position and updates state.
    private func handleFaceDetected(frameData: FaceFrameData, sampleBuffer: CMSampleBuffer) {
        let newReadiness = computeReadiness(frameData: frameData)
        readiness = newReadiness
        previousFrameData = frameData

        if newReadiness == .ready {
            lastSampleBuffer = sampleBuffer
            updateHoldProgress()
        } else {
            resetHoldState()
            scanInstruction = newReadiness.message
        }
    }

    // MARK: - Readiness Computation

    /// Determines the current face readiness state based on validation checks.
    /// Checks are ordered by priority: position → proximity → pose → stability.
    private func computeReadiness(frameData: FaceFrameData) -> FaceScanReadiness {
        // 1. Position check — face center must be within guide area
        guard FaceValidation.isPositionValid(boundingBox: frameData.boundingBox) else {
            return .faceOutOfGuide
        }

        // 2. Proximity check — face must be close enough
        guard FaceValidation.isProximityValid(faceWidth: frameData.boundingBox.width) else {
            return .tooFar
        }

        // 3. Pose match — face must match target angle
        let yaw = frameData.yaw ?? 0.0
        let pitch = frameData.pitch ?? 0.0
        guard FaceValidation.isPoseMatched(
            yaw: yaw,
            pitch: pitch,
            target: currentAngleTarget
        ) else {
            return .wrongAngle(currentAngleTarget.displayName)
        }

        // 4. Stability check — face must not be moving excessively
        if let previous = previousFrameData {
            guard FaceValidation.isStable(current: frameData, previous: previous) else {
                return .unstable
            }
        }

        return .ready
    }

    // MARK: - Hold-to-Capture State Machine

    /// Updates hold progress when face is ready. Triggers capture at 1.0.
    private func updateHoldProgress() {
        if holdStartTime == nil {
            holdStartTime = Date()
        }

        guard let startTime = holdStartTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        holdProgress = min(elapsed / holdDuration, 1.0)
        scanInstruction = currentAngleTarget.instruction

        if holdProgress >= 1.0 {
            captureCurrentFrame()
        }
    }

    /// Resets the hold timer and progress when face loses readiness.
    private func resetHoldState() {
        holdStartTime = nil
        holdProgress = 0.0
    }

    /// Captures the current frame as JPEG, stores it, and advances to the next angle.
    /// Transitions to error state if JPEG extraction fails (Requirement 8.3).
    private func captureCurrentFrame() {
        guard let sampleBuffer = lastSampleBuffer else { return }

        // Convert CMSampleBuffer → CGImage → JPEG Data
        guard let jpegData = extractJPEGData(from: sampleBuffer) else {
            // Capture failed — transition to error state (Requirement 8.3)
            phase = .error(message: "Gagal mengambil gambar")
            stopSession()
            return
        }

        // Store captured image for the current angle
        capturedImages[currentAngleTarget] = jpegData
        completedAngles = capturedImages.count

        // Reset hold state for the next angle
        resetHoldState()
        lastSampleBuffer = nil

        // Advance to next angle or transition to processing
        advanceToNextAngle()
    }

    /// Advances to the next angle target after a successful capture.
    /// Transitions to `.processing` when all 3 angles are captured, then runs inference.
    private func advanceToNextAngle() {
        guard let currentIndex = angleSequence.firstIndex(of: currentAngleTarget) else {
            return
        }

        let nextIndex = currentIndex + 1

        if nextIndex < angleSequence.count {
            // Move to next angle
            currentAngleTarget = angleSequence[nextIndex]
            scanInstruction = currentAngleTarget.instruction
            readiness = .searchingFace
            previousFrameData = nil
        } else {
            // All 3 angles captured — transition to processing and run inference
            stopSession()
            phase = .processing
            runInference()
        }
    }

    // MARK: - ML Inference

    /// Runs acne detection concurrently on all captured images.
    /// On success: builds result model and transitions to `.completed`.
    /// On failure: transitions to `.error` with descriptive message (Requirement 5.7, 8.3).
    private func runInference() {
        Task {
            do {
                // Run inference concurrently on all 3 captured angle images
                let frontDetections = try await detectAcne(for: .front)
                let leftDetections = try await detectAcne(for: .leftAngle)
                let rightDetections = try await detectAcne(for: .rightAngle)

                // Build zone results
                let zoneResults = buildZoneResults(
                    front: frontDetections,
                    left: leftDetections,
                    right: rightDetections
                )

                // Calculate totals
                let totalCount = zoneResults.reduce(0) { $0 + $1.detections.count }
                let severity = AcneSeverity(totalCount: totalCount)

                // Build session
                let session = FaceScanSession(
                    id: UUID(),
                    capturedAt: Date(),
                    overallImageData: capturedImages[.front] ?? Data(),
                    zoneResults: zoneResults,
                    totalAcneCount: totalCount,
                    overallSeverity: severity
                )

                // Map to presentation model
                let resultModel = mapToResultModel(session: session)
                phase = .completed(resultModel)
            } catch {
                phase = .error(message: "Gagal menganalisis gambar")
            }
        }
    }

    /// Runs acne detection on the captured image for a specific zone.
    private func detectAcne(for zone: FaceZone) async throws -> [AcneDetection] {
        guard let imageData = capturedImages[zone],
              let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            throw AppError.unknown(message: "Gambar tidak valid untuk zona \(zone.displayName)")
        }
        return try await acneDetectionService.detect(in: cgImage)
    }

    /// Builds FaceZoneScanResult array from detection results.
    private func buildZoneResults(
        front: [AcneDetection],
        left: [AcneDetection],
        right: [AcneDetection]
    ) -> [FaceZoneScanResult] {
        return [
            FaceZoneScanResult(
                id: UUID(),
                zone: .front,
                detections: front,
                capturedImageData: capturedImages[.front] ?? Data()
            ),
            FaceZoneScanResult(
                id: UUID(),
                zone: .leftAngle,
                detections: left,
                capturedImageData: capturedImages[.leftAngle] ?? Data()
            ),
            FaceZoneScanResult(
                id: UUID(),
                zone: .rightAngle,
                detections: right,
                capturedImageData: capturedImages[.rightAngle] ?? Data()
            )
        ]
    }

    /// Maps a FaceScanSession to a FaceScanResultModel for presentation.
    private func mapToResultModel(session: FaceScanSession) -> FaceScanResultModel {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "id_ID")

        // Build zone summaries
        let zoneSummaries: [ZoneSummaryModel] = session.zoneResults.map { zoneResult in
            let markers = zoneResult.detections.map { detection in
                MarkerModel(
                    id: UUID(),
                    acneType: detection.acneType,
                    confidence: detection.confidence,
                    normalizedPosition: CGPoint(
                        x: detection.normalizedBoundingBox.midX,
                        y: detection.normalizedBoundingBox.midY
                    )
                )
            }

            return ZoneSummaryModel(
                id: UUID(),
                zoneName: zoneResult.zone.displayName,
                acneCount: zoneResult.detections.count,
                detailText: "\(zoneResult.detections.count) jerawat terdeteksi",
                imageData: zoneResult.capturedImageData,
                markers: markers
            )
        }

        // Build acne type summaries sorted descending by count (Requirement 7.4)
        var typeCounts: [AcneType: Int] = [:]
        for zoneResult in session.zoneResults {
            for detection in zoneResult.detections {
                typeCounts[detection.acneType, default: 0] += 1
            }
        }
        let acneTypeSummaries = typeCounts.map { type, count in
            AcneTypeSummaryModel(acneType: type, count: count)
        }.sorted { $0.count > $1.count }

        return FaceScanResultModel(
            id: session.id,
            dateText: dateFormatter.string(from: session.capturedAt),
            overallSeverityText: session.overallSeverity.rawValue.capitalized,
            totalAcneCountText: "\(session.totalAcneCount) jerawat",
            zoneSummaries: zoneSummaries,
            acneTypeSummaries: acneTypeSummaries
        )
    }

    // MARK: - Image Extraction

    /// Converts a CMSampleBuffer to JPEG Data.
    /// The pixel buffer is already in portrait orientation (rotated + mirrored by the
    /// AVCaptureConnection settings), so we simply encode it as-is with .up orientation.
    private func extractJPEGData(from sampleBuffer: CMSampleBuffer) -> Data? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        // Buffer is already portrait-oriented thanks to connection's
        // videoRotationAngle=90 and isVideoMirrored=true.
        // No additional rotation needed.
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        return uiImage.jpegData(compressionQuality: jpegCompressionQuality)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension FaceScanViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Run Vision face detection on the video processing queue (already here),
        // then dispatch state updates to MainActor.
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest()
        // Buffer is already portrait-oriented (videoRotationAngle=90, isVideoMirrored=true),
        // so tell Vision the orientation is .up.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        do {
            try handler.perform([request])
        } catch {
            Task { @MainActor [weak self] in
                self?.handleNoFaceDetected()
            }
            return
        }

        guard let faceObservation = request.results?.first else {
            Task { @MainActor [weak self] in
                self?.handleNoFaceDetected()
            }
            return
        }

        let boundingBox = faceObservation.boundingBox
        let yaw = faceObservation.yaw?.doubleValue
        let pitch = faceObservation.pitch?.doubleValue
        let frameData = FaceFrameData(boundingBox: boundingBox, yaw: yaw, pitch: pitch)

        Task { @MainActor [weak self] in
            self?.handleFaceDetected(frameData: frameData, sampleBuffer: sampleBuffer)
        }
    }
}
