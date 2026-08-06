import Foundation
import Combine
import AVFoundation
import Vision
import UIKit
import ImageIO

@MainActor
final class FaceScanViewModel: NSObject, ObservableObject {
    @Published private(set) var phase: FaceScanPhase = .positioningFace
    @Published private(set) var lightingCondition: LightingCondition = .acceptable
    @Published private(set) var isFaceInPosition: Bool = false
    @Published private(set) var completedZones: [FaceZone] = []
    @Published private(set) var currentZone: FaceZone = .forehead
    @Published private(set) var zoneProgress: Double = 0.0 // 0.0–1.0 hold progress for current zone
    @Published private(set) var readiness: FaceScanReadiness = .searchingFace
    @Published private(set) var scanTargetZones: [FaceZone] = CapturePose.frontal.zones
    @Published private(set) var scanInstruction: String = CapturePose.frontal.instruction

    let captureSession = AVCaptureSession()

    private let performScanUseCase: PerformFaceScanUseCase
    private let mapper: FaceScanPresentationMapper
    private let logger: AppLogging

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sampleQueue = DispatchQueue(label: "suzuran.facescan.videoQueue")
    private var capturedZoneData: [(zone: FaceZone, imageData: Data)] = []
    private var currentCapturePose: CapturePose = .frontal

    // --- Frame Processing Guards ---
    private var isProcessingFrame = false          // Prevents overlapping Vision requests
    private var isCapturingZone = false             // Prevents double-capture
    private var isScanActive = false                // Ignores frames after the final capture
    private var lastCaptureTime = Date.distantPast  // Cooldown timer between zones
    private var previousValidatedFace: FaceFrameData?

    // --- Hold-to-Capture Logic ---
    /// User must hold the correct position for this duration before capture
    private let holdDurationRequired: TimeInterval = 0.8
    private var holdStartTime: Date?                // When user first held correct position
    private var lastMatchedZone: FaceZone?          // Which zone was being matched

    /// Cooldown between zone captures (gives user time to read next instruction)
    private let captureCooldown: TimeInterval = 1.5

    init(
        performScanUseCase: PerformFaceScanUseCase,
        mapper: FaceScanPresentationMapper,
        logger: AppLogging
    ) {
        self.performScanUseCase = performScanUseCase
        self.mapper = mapper
        self.logger = logger
        super.init()
    }

    func startScan() {
        checkCameraPermission()
    }

    func stopScan() {
        isScanActive = false
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    func retry() {
        completedZones.removeAll()
        capturedZoneData.removeAll()
        currentZone = .forehead
        currentCapturePose = .frontal
        scanTargetZones = CapturePose.frontal.zones
        scanInstruction = CapturePose.frontal.instruction
        holdStartTime = nil
        lastMatchedZone = nil
        zoneProgress = 0.0
        updateReadiness(.searchingFace)
        previousValidatedFace = nil
        phase = .positioningFace
        startScan()
    }

    // MARK: - Camera Permission

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCameraSession()
        case .notDetermined:
            phase = .requestingPermission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if granted {
                        self.setupCameraSession()
                    } else {
                        self.phase = .permissionDenied
                    }
                }
            }
        default:
            phase = .permissionDenied
        }
    }

    // MARK: - Camera Setup

    private func setupCameraSession() {
        guard !captureSession.isRunning else { return }
        isScanActive = true

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high  // High resolution preview & crisp capture

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            logger.error("Failed to access front camera")
            phase = .error(message: "Kamera depan tidak tersedia.")
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        // Drop late frames to avoid queue buildup
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: sampleQueue)
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()

        Task.detached(priority: .userInitiated) { [weak self] in
            self?.captureSession.startRunning()
        }

        phase = .scanning(currentZone: .forehead, capturedCount: 0)
    }

    // MARK: - Frame Processing (runs on sampleQueue)

    /// Called from the background sampleQueue — do NOT touch @Published properties directly here
    nonisolated private func processFrameOnBackground(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // 1. Calculate lighting from EXIF metadata (lightweight)
        let brightness = Self.extractBrightness(from: sampleBuffer)

        // 2. Run Vision face detection on background thread
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return
        }

        let faceResults = request.results as? [VNFaceObservation]
        let face = faceResults?.first

        // 3. Prepare data to send to MainActor
        let faceData: FaceFrameData?
        if let face = face {
            faceData = FaceFrameData(
                boundingBox: face.boundingBox,
                yaw: face.yaw?.doubleValue,
                pitch: face.pitch?.doubleValue,
                landmarks: LandmarkAvailability(landmarks: face.landmarks)
            )
        } else {
            faceData = nil
        }

        // 4. Send lightweight results to main thread
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.handleFaceDetectionResult(faceData: faceData, brightness: brightness, pixelBuffer: pixelBuffer)
            self.isProcessingFrame = false
        }
    }

    /// Lightweight struct passed from background to main thread
    private struct FaceFrameData {
        let boundingBox: CGRect
        let yaw: Double?
        let pitch: Double?
        let landmarks: LandmarkAvailability
    }

    private struct LandmarkAvailability {
        let leftEyePoints: Int
        let rightEyePoints: Int
        let leftEyebrowPoints: Int
        let rightEyebrowPoints: Int
        let nosePoints: Int
        let outerLipPoints: Int
        let contourPoints: Int

        init(landmarks: VNFaceLandmarks2D?) {
            leftEyePoints = landmarks?.leftEye?.pointCount ?? 0
            rightEyePoints = landmarks?.rightEye?.pointCount ?? 0
            leftEyebrowPoints = landmarks?.leftEyebrow?.pointCount ?? 0
            rightEyebrowPoints = landmarks?.rightEyebrow?.pointCount ?? 0
            nosePoints = landmarks?.nose?.pointCount ?? 0
            outerLipPoints = landmarks?.outerLips?.pointCount ?? 0
            contourPoints = landmarks?.faceContour?.pointCount ?? 0
        }
    }

    nonisolated private static func extractBrightness(from sampleBuffer: CMSampleBuffer) -> Double? {
        guard let rawData = CMGetAttachment(sampleBuffer, key: kCGImagePropertyExifDictionary, attachmentModeOut: nil) as? [String: Any],
              let brightness = rawData[kCGImagePropertyExifBrightnessValue as String] as? Double else {
            return nil
        }
        return brightness
    }

    // MARK: - Main Thread Processing

    private func handleFaceDetectionResult(faceData: FaceFrameData?, brightness: Double?, pixelBuffer: CVPixelBuffer) {
        // Update lighting
        if let brightness = brightness {
            if brightness < -1.5 {
                lightingCondition = .tooLow
            } else if brightness < 2.0 {
                lightingCondition = .acceptable
            } else {
                lightingCondition = .good
            }
        }

        // No face detected
        guard let face = faceData else {
            isFaceInPosition = false
            updateReadiness(.searchingFace)
            resetCaptureHold()
            return
        }

        // Check if face is reasonably centered (relaxed thresholds)
        let bb = face.boundingBox
        let isCentered = bb.midX >= 0.15 && bb.midX <= 0.85 &&
                         bb.midY >= 0.15 && bb.midY <= 0.85 &&
                         bb.width >= 0.20  // Face takes at least 20% of frame width

        isFaceInPosition = isCentered

        guard isCentered else {
            updateReadiness(.faceOutOfGuide)
            resetCaptureHold()
            return
        }

        guard lightingCondition != .tooLow else {
            updateReadiness(.insufficientLighting)
            resetCaptureHold()
            return
        }

        // Check cooldown between captures
        guard !isCapturingZone && Date().timeIntervalSince(lastCaptureTime) > captureCooldown else {
            return
        }

        guard isTargetVisible(for: currentCapturePose, landmarks: face.landmarks) else {
            updateReadiness(.targetNotVisible(targetNotVisibleMessage(for: currentCapturePose)))
            resetCaptureHold()
            return
        }

        guard isCapturePoseMatch(currentCapturePose, yaw: face.yaw, pitch: face.pitch) else {
            updateReadiness(.wrongPose(currentCapturePose.instruction))
            resetCaptureHold()
            return
        }

        guard isFaceStable(face) else {
            updateReadiness(.unstable)
            resetCaptureHold(keepingPreviousFace: true)
            return
        }

        updateReadiness(.ready)
        // Start or continue hold timer
        if holdStartTime == nil || lastMatchedZone != currentZone {
            holdStartTime = Date()
            lastMatchedZone = currentZone
        }

        let holdDuration = Date().timeIntervalSince(holdStartTime!)
        zoneProgress = min(holdDuration / holdDurationRequired, 1.0)

        // Capture only after pose, landmarks, lighting, and stability are valid.
        if holdDuration >= holdDurationRequired {
            captureCurrentPose(from: pixelBuffer, face: face)
        }
    }

    // MARK: - Zone Validation

    private func isCapturePoseMatch(_ pose: CapturePose, yaw: Double?, pitch: Double?) -> Bool {
        // Vision may omit yaw/pitch for a front-facing face. Treat that as a
        // neutral pose for frontal zones, but require an explicit measurement
        // for zones that need a pronounced turn or tilt.
        let neutralYaw = yaw ?? 0
        let neutralPitch = pitch ?? 0

        switch pose {
        case .frontal:
            // One stable frontal frame supplies the forehead, nose, and chin.
            return abs(neutralYaw) < 0.25 && neutralPitch < 0.10
        case .rightCheek:
            guard let yaw else { return false }
            return yaw < -0.20 && abs(neutralPitch) < 0.20
        case .leftCheek:
            guard let yaw else { return false }
            return yaw > 0.20 && abs(neutralPitch) < 0.20
        }
    }

    private func isTargetVisible(for pose: CapturePose, landmarks: LandmarkAvailability) -> Bool {
        let hasBothEyes = landmarks.leftEyePoints >= 4 && landmarks.rightEyePoints >= 4
        let hasBothBrows = landmarks.leftEyebrowPoints >= 3 && landmarks.rightEyebrowPoints >= 3
        let hasContour = landmarks.contourPoints >= 8

        switch pose {
        case .frontal:
            return hasBothEyes && hasBothBrows
        case .rightCheek:
            return landmarks.leftEyePoints >= 4 && landmarks.leftEyebrowPoints >= 3 && hasContour
        case .leftCheek:
            return landmarks.rightEyePoints >= 4 && landmarks.rightEyebrowPoints >= 3 && hasContour
        }
    }

    private func targetNotVisibleMessage(for pose: CapturePose) -> String {
        switch pose {
        case .frontal: return "Pastikan jidat dan kedua alis terlihat"
        case .rightCheek: return "Pastikan pipi kanan terlihat jelas"
        case .leftCheek: return "Pastikan pipi kiri terlihat jelas"
        }
    }

    private func isFaceStable(_ face: FaceFrameData) -> Bool {
        defer { previousValidatedFace = face }
        guard let previous = previousValidatedFace else { return true }

        let positionDelta = hypot(
            face.boundingBox.midX - previous.boundingBox.midX,
            face.boundingBox.midY - previous.boundingBox.midY
        )
        let sizeDelta = abs(face.boundingBox.width - previous.boundingBox.width)
        let yawDelta = abs((face.yaw ?? 0) - (previous.yaw ?? 0))
        let pitchDelta = abs((face.pitch ?? 0) - (previous.pitch ?? 0))

        return positionDelta < 0.025 && sizeDelta < 0.03 && yawDelta < 0.06 && pitchDelta < 0.06
    }

    private func resetCaptureHold(keepingPreviousFace: Bool = false) {
        holdStartTime = nil
        lastMatchedZone = nil
        zoneProgress = 0.0
        if !keepingPreviousFace {
            previousValidatedFace = nil
        }
    }

    private func updateReadiness(_ newValue: FaceScanReadiness) {
        guard readiness != newValue else { return }
        readiness = newValue
        logger.info("Face scan validation: \(newValue.message)")
    }

    // MARK: - Canonical Five-Zone Capture

    private func captureCurrentPose(from pixelBuffer: CVPixelBuffer, face: FaceFrameData) {
        isCapturingZone = true
        lastCaptureTime = Date()
        holdStartTime = nil
        zoneProgress = 0.0
        updateReadiness(.searchingFace)
        previousValidatedFace = nil

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            .oriented(forExifOrientation: Int32(CGImagePropertyOrientation.leftMirrored.rawValue))
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            isCapturingZone = false
            return
        }

        let uiImage = UIImage(cgImage: cgImage)
        let zones = currentCapturePose.zones
        let zoneCaptures = zones.compactMap { zone -> (zone: FaceZone, imageData: Data)? in
            guard let imageData = cropFaceZone(zone, from: uiImage, faceBoundingBox: face.boundingBox) else {
                return nil
            }
            return (zone, imageData)
        }

        guard zoneCaptures.count == zones.count else {
            isCapturingZone = false
            updateReadiness(.targetNotVisible("Area wajah belum dapat dipetakan — coba lagi"))
            return
        }

        capturedZoneData.append(contentsOf: zoneCaptures)
        completedZones.append(contentsOf: zones)

        logger.info("Captured pose: \(currentCapturePose.logName), mapped zones: \(zones.map(\.displayName).joined(separator: ", "))")

        if let nextPose = currentCapturePose.next {
            currentCapturePose = nextPose
            currentZone = nextPose.primaryZone
            scanTargetZones = nextPose.zones
            scanInstruction = nextPose.instruction
            phase = .scanning(currentZone: nextPose.primaryZone, capturedCount: completedZones.count)
        } else {
            finishAllCaptures()
            return
        }

        // Reset for next zone after a short delay
        isCapturingZone = false
    }

    private func cropFaceZone(_ zone: FaceZone, from image: UIImage, faceBoundingBox: CGRect) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let region = canonicalRegion(for: zone)
        let normalizedCrop = CGRect(
            x: faceBoundingBox.minX + faceBoundingBox.width * region.minX,
            y: faceBoundingBox.minY + faceBoundingBox.height * region.minY,
            width: faceBoundingBox.width * region.width,
            height: faceBoundingBox.height * region.height
        ).intersection(CGRect(x: 0, y: 0, width: 1, height: 1))

        guard !normalizedCrop.isNull, normalizedCrop.width > 0, normalizedCrop.height > 0 else { return nil }

        let cropRect = CGRect(
            x: normalizedCrop.minX * CGFloat(cgImage.width),
            y: (1 - normalizedCrop.maxY) * CGFloat(cgImage.height),
            width: normalizedCrop.width * CGFloat(cgImage.width),
            height: normalizedCrop.height * CGFloat(cgImage.height)
        ).integral

        guard let croppedImage = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: croppedImage).jpegData(compressionQuality: 0.82)
    }

    private func canonicalRegion(for zone: FaceZone) -> CGRect {
        switch zone {
        case .forehead: return CGRect(x: 0.22, y: 0.65, width: 0.56, height: 0.27)
        case .rightCheek: return CGRect(x: 0.02, y: 0.25, width: 0.38, height: 0.42)
        case .leftCheek: return CGRect(x: 0.60, y: 0.25, width: 0.38, height: 0.42)
        case .nose: return CGRect(x: 0.37, y: 0.34, width: 0.26, height: 0.34)
        case .chin: return CGRect(x: 0.28, y: 0.05, width: 0.44, height: 0.25)
        case .jawline: return CGRect(x: 0.12, y: 0.03, width: 0.76, height: 0.32)
        }
    }

    private enum CapturePose: CaseIterable {
        case frontal
        case rightCheek
        case leftCheek

        var zones: [FaceZone] {
            switch self {
            case .frontal: return [.forehead, .nose, .chin]
            case .rightCheek: return [.rightCheek]
            case .leftCheek: return [.leftCheek]
            }
        }

        var primaryZone: FaceZone { zones[0] }

        var instruction: String {
            switch self {
            case .frontal: return "Hadapkan wajah lurus untuk jidat, hidung, dan dagu"
            case .rightCheek: return "Putar wajah sedikit ke KIRI agar pipi kanan terlihat"
            case .leftCheek: return "Putar wajah sedikit ke KANAN agar pipi kiri terlihat"
            }
        }

        var next: CapturePose? {
            switch self {
            case .frontal: return .rightCheek
            case .rightCheek: return .leftCheek
            case .leftCheek: return nil
            }
        }

        var logName: String {
            switch self {
            case .frontal: return "frontal"
            case .rightCheek: return "right cheek"
            case .leftCheek: return "left cheek"
            }
        }
    }

    // MARK: - Finish Scan

    private func finishAllCaptures() {
        stopScan()
        phase = .processing

        Task {
            do {
                logger.info("Starting ML analysis for \(capturedZoneData.count) face zones")
                let session = try await performScanUseCase.execute(zoneCaptures: capturedZoneData)
                let resultModel = mapper.map(session)
                phase = .completed(resultModel)
            } catch {
                logger.error("Face scan processing failed: \(error.localizedDescription)")
                phase = .error(message: FaceScanErrorTextMapper.message(for: error))
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension FaceScanViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Skip frame if still processing previous one (frame throttling)
        Task { @MainActor [weak self] in
            guard let self = self, self.isScanActive, !self.isProcessingFrame else { return }
            self.isProcessingFrame = true

            // Process on background queue — NOT on main thread
            self.sampleQueue.async { [weak self] in
                self?.processFrameOnBackground(sampleBuffer: sampleBuffer)
            }
        }
    }
}
