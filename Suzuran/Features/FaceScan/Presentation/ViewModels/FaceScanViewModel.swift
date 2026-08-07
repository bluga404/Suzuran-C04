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
    @Published private(set) var proximity: FaceProximity = .tooFar
    @Published private(set) var isFaceInPosition: Bool = false
    @Published private(set) var zoneProgress: Double = 0.0 // 0.0–1.0 hold progress
    @Published private(set) var readiness: FaceScanReadiness = .searchingFace
    @Published private(set) var scanInstruction: String = FaceZone.front.instruction
    @Published private(set) var currentAngleTarget: FaceZone = .front

    private var frontFullData: Data?
    private var frontTZoneData: Data?
    private var frontTZoneRect: CGRect?
    private var leftFullData: Data?
    private var rightFullData: Data?

    let captureSession = AVCaptureSession()

    private let performScanUseCase: PerformFaceScanUseCase
    private let mapper: FaceScanPresentationMapper
    private let logger: AppLogging

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sampleQueue = DispatchQueue(label: "suzuran.facescan.videoQueue")

    // --- Frame Processing Guards ---
    private var isProcessingFrame = false
    private var isCapturing = false
    private var isScanActive = false
    private var previousValidatedFace: FaceFrameData?

    // --- Hold-to-Capture Logic ---
    private let holdDurationRequired: TimeInterval = 1.0
    private var holdStartTime: Date?

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
        holdStartTime = nil
        zoneProgress = 0.0
        currentAngleTarget = .front
        scanInstruction = currentAngleTarget.instruction
        frontFullData = nil
        frontTZoneData = nil
        frontTZoneRect = nil
        leftFullData = nil
        rightFullData = nil
        updateReadiness(.searchingFace)
        previousValidatedFace = nil
        phase = .positioningFace
        isCapturing = false
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
        captureSession.sessionPreset = .high

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

        videoOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: sampleQueue)
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()

        Task.detached(priority: .userInitiated) { [weak self] in
            self?.captureSession.startRunning()
        }

        phase = .capturing
    }

    // MARK: - Frame Processing (runs on sampleQueue)

    nonisolated private func processFrameOnBackground(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let brightness = Self.extractBrightness(from: sampleBuffer)

        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return
        }

        let faceResults = request.results as? [VNFaceObservation]
        let faceObs = faceResults?.first

        let faceData: FaceFrameData?
        if let face = faceObs {
            faceData = FaceFrameData(
                observation: face,
                boundingBox: face.boundingBox,
                yaw: face.yaw?.doubleValue,
                pitch: face.pitch?.doubleValue,
                landmarks: LandmarkAvailability(landmarks: face.landmarks)
            )
        } else {
            faceData = nil
        }

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.handleFaceDetectionResult(faceData: faceData, brightness: brightness, pixelBuffer: pixelBuffer)
            self.isProcessingFrame = false
        }
    }

    private struct FaceFrameData {
        let observation: VNFaceObservation
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
        if let brightness = brightness {
            if brightness < -1.5 {
                lightingCondition = .tooLow
            } else if brightness < 2.0 {
                lightingCondition = .acceptable
            } else {
                lightingCondition = .good
            }
        }

        guard let face = faceData else {
            isFaceInPosition = false
            updateReadiness(.searchingFace)
            resetCaptureHold()
            return
        }

        let bb = face.boundingBox
        let isCentered = bb.midX >= 0.25 && bb.midX <= 0.75 &&
                         bb.midY >= 0.25 && bb.midY <= 0.75
        isFaceInPosition = isCentered

        guard isCentered else {
            updateReadiness(.faceOutOfGuide)
            resetCaptureHold()
            return
        }
        
        let width = bb.width
        if width < 0.55 {
            proximity = .tooFar
        } else if width > 0.95 {
            // Unlikely, but if too close
            proximity = .acceptable
        } else {
            proximity = .ideal
        }

        guard proximity == .ideal else {
            updateReadiness(.targetNotVisible("Dekatkan wajah ke kamera"))
            resetCaptureHold()
            return
        }

        guard lightingCondition != .tooLow else {
            updateReadiness(.insufficientLighting)
            resetCaptureHold()
            return
        }

        guard !isCapturing else {
            return
        }

        guard isTargetVisible(landmarks: face.landmarks) else {
            updateReadiness(.targetNotVisible("Pastikan seluruh bagian wajah terlihat"))
            resetCaptureHold()
            return
        }

        guard isCapturePoseMatch(yaw: face.yaw, pitch: face.pitch) else {
            switch currentAngleTarget {
            case .front: updateReadiness(.targetNotVisible("Hadapkan wajah lurus ke depan"))
            case .leftAngle: updateReadiness(.targetNotVisible("Putar wajah Anda ke kiri"))
            case .rightAngle: updateReadiness(.targetNotVisible("Putar wajah Anda ke kanan"))
            default: updateReadiness(.targetNotVisible("Sesuaikan posisi wajah Anda"))
            }
            resetCaptureHold()
            return
        }

        guard isFaceStable(face) else {
            updateReadiness(.unstable)
            resetCaptureHold(keepingPreviousFace: true)
            return
        }

        updateReadiness(.ready)
        if holdStartTime == nil {
            holdStartTime = Date()
        }

        let holdDuration = Date().timeIntervalSince(holdStartTime!)
        zoneProgress = min(holdDuration / holdDurationRequired, 1.0)

        if holdDuration >= holdDurationRequired {
            captureFrame(from: pixelBuffer, face: face)
        }
    }

    // MARK: - Zone Validation

    private func isCapturePoseMatch(yaw: Double?, pitch: Double?) -> Bool {
        let neutralYaw = yaw ?? 0
        let neutralPitch = pitch ?? 0
        
        switch currentAngleTarget {
        case .front:
            return abs(neutralYaw) < 0.25 && neutralPitch < 0.15
        case .leftAngle:
            return neutralYaw > 0.40 && neutralPitch < 0.15
        case .rightAngle:
            return neutralYaw < -0.40 && neutralPitch < 0.15
        default:
            return false
        }
    }

    private func isTargetVisible(landmarks: LandmarkAvailability) -> Bool {
        let hasBothEyes = landmarks.leftEyePoints >= 4 && landmarks.rightEyePoints >= 4
        let hasBothBrows = landmarks.leftEyebrowPoints >= 3 && landmarks.rightEyebrowPoints >= 3
        let hasNose = landmarks.nosePoints >= 3
        let hasLips = landmarks.outerLipPoints >= 8
        let hasContour = landmarks.contourPoints >= 8

        return hasBothEyes && hasBothBrows && hasNose && hasLips && hasContour
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

    // MARK: - Capture & Process

    private func captureFrame(from pixelBuffer: CVPixelBuffer, face: FaceFrameData) {
        isCapturing = true
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            .oriented(forExifOrientation: Int32(CGImagePropertyOrientation.leftMirrored.rawValue))
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            handleError("Gagal mengambil gambar.")
            return
        }

        let uiImage = UIImage(cgImage: cgImage)
        guard let fullFaceData = uiImage.jpegData(compressionQuality: 0.82) else {
            handleError("Gagal memproses gambar.")
            return
        }

        switch currentAngleTarget {
        case .front:
            frontFullData = fullFaceData
            
            // Map T-Zone using FaceLandmarkZoneMapper
            if let tZoneNormalized = FaceLandmarkZoneMapper.mapTZone(from: face.observation),
               let tZoneCropData = cropFaceZone(normalizedRect: tZoneNormalized, from: uiImage, faceBoundingBox: face.boundingBox) {
                frontTZoneData = tZoneCropData
                frontTZoneRect = tZoneNormalized
            } else {
                handleError("Gagal memetakan T-Zone wajah. Pastikan wajah terlihat jelas.")
                return
            }
            
            currentAngleTarget = .leftAngle
            resetCaptureHold(keepingPreviousFace: false)
            scanInstruction = currentAngleTarget.instruction
            isCapturing = false
            
        case .leftAngle:
            leftFullData = fullFaceData
            
            currentAngleTarget = .rightAngle
            resetCaptureHold(keepingPreviousFace: false)
            scanInstruction = currentAngleTarget.instruction
            isCapturing = false
            
        case .rightAngle:
            rightFullData = fullFaceData
            
            guard let frontFull = frontFullData,
                  let frontTZone = frontTZoneData,
                  let frontTZoneRect = frontTZoneRect,
                  let leftFull = leftFullData,
                  let rightFull = rightFullData else {
                handleError("Data gambar tidak lengkap.")
                return
            }
            
            stopScan()
            phase = .processing
            
            Task {
                do {
                    logger.info("Starting ML analysis for 3 angles")
                    let session = try await performScanUseCase.execute(
                        frontFullImageData: frontFull,
                        frontTZoneImageData: frontTZone,
                        frontTZoneRect: frontTZoneRect,
                        leftImageData: leftFull,
                        rightImageData: rightFull
                    )
                    let resultModel = mapper.map(session)
                    phase = .completed(resultModel)
                } catch {
                    logger.error("Face scan processing failed: \(error.localizedDescription)")
                    handleError(FaceScanErrorTextMapper.message(for: error))
                }
            }
            
        default:
            break
        }
    }

    private func cropFaceZone(normalizedRect: CGRect, from image: UIImage, faceBoundingBox: CGRect) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        // normalizedRect is relative to the faceBoundingBox.
        let actualRect = CGRect(
            x: faceBoundingBox.minX + faceBoundingBox.width * normalizedRect.minX,
            y: faceBoundingBox.minY + faceBoundingBox.height * normalizedRect.minY,
            width: faceBoundingBox.width * normalizedRect.width,
            height: faceBoundingBox.height * normalizedRect.height
        ).intersection(CGRect(x: 0, y: 0, width: 1, height: 1))

        guard !actualRect.isNull, actualRect.width > 0, actualRect.height > 0 else { return nil }

        let cropRect = CGRect(
            x: actualRect.minX * CGFloat(cgImage.width),
            y: (1 - actualRect.maxY) * CGFloat(cgImage.height),
            width: actualRect.width * CGFloat(cgImage.width),
            height: actualRect.height * CGFloat(cgImage.height)
        ).integral

        guard let croppedImage = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: croppedImage).jpegData(compressionQuality: 0.82)
    }
    
    private func handleError(_ message: String) {
        phase = .error(message: message)
        isCapturing = false
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension FaceScanViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        Task { @MainActor [weak self] in
            guard let self = self, self.isScanActive, !self.isProcessingFrame else { return }
            self.isProcessingFrame = true

            self.sampleQueue.async { [weak self] in
                self?.processFrameOnBackground(sampleBuffer: sampleBuffer)
            }
        }
    }
}
