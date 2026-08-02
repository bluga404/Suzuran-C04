@preconcurrency import AVFoundation
import Combine
import UIKit
import Vision

final class FaceScanSessionService: NSObject, FaceScanSessionServicing {
    private let sessionQueue = DispatchQueue(label: "com.suzuran.facescan.session", qos: .userInitiated)
    private let analysisQueue = DispatchQueue(label: "com.suzuran.facescan.analysis", qos: .userInitiated)

    private(set) lazy var session: AVCaptureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let analyzer = FaceScanPoseAnalyzer()

    private var isSessionConfigured = false
    private var selectedFlashOption: FaceScanFlashOption = .off
    private var activePhotoCaptureDelegate: FaceScanPhotoCaptureDelegate?

    private var remainingTargets = FaceScanArea.captureOrder
    private var currentTargetArea: FaceScanArea?
    private var stableFrameCount = 0
    private var cooldownFrameCount = 0
    private var isCaptureInProgress = false
    private var capturedArtifacts: [FaceScanCaptureArtifact] = []

    private var lastAnalyzedTimestamp: CMTime = .zero
    private let analysisInterval = CMTime(value: 1, timescale: 8)
    private let requiredStableFrames = 6
    private let cooldownFrames = 8

    private let progressSubject = CurrentValueSubject<FaceScanProgressSnapshot, Never>(
        FaceScanProgressSnapshot(
            status: .idle,
            currentTarget: FaceScanArea.captureOrder.first,
            capturedAreas: [],
            isFaceDetected: false,
            stabilityProgress: 0,
            hint: "Align your face to begin."
        )
    )
    private let captureSubject = PassthroughSubject<FaceScanCaptureArtifact, Never>()
    private let completionSubject = PassthroughSubject<[FaceScanCaptureArtifact], Never>()
    private let errorSubject = PassthroughSubject<String, Never>()

    var progressPublisher: AnyPublisher<FaceScanProgressSnapshot, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    var capturePublisher: AnyPublisher<FaceScanCaptureArtifact, Never> {
        captureSubject.eraseToAnyPublisher()
    }

    var completionPublisher: AnyPublisher<[FaceScanCaptureArtifact], Never> {
        completionSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    var isCameraAvailable: Bool {
        preferredFrontCamera() != nil
    }

    var isSessionRunning: Bool {
        session.isRunning
    }

    deinit {
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func requestAccess(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func startSession(completion: @escaping (Result<Void, Error>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            guard self.authorizationStatus == .authorized else {
                DispatchQueue.main.async {
                    completion(.failure(FaceScanError.permissionDenied))
                }
                return
            }

            if !self.isSessionConfigured {
                do {
                    try self.configureSession()
                } catch {
                    self.publishError(error.localizedDescription)
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
            }

            if !self.session.isRunning {
                self.publishPreparingState()
                self.session.startRunning()
            }

            self.resetFlowState(clearCaptures: true)
            self.publishScanningState(faceDetected: false, stability: 0, hint: self.currentTarget?.instruction ?? "Align your face to begin.")

            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.activePhotoCaptureDelegate = nil
            self.isCaptureInProgress = false
            self.stableFrameCount = 0
            self.cooldownFrameCount = 0

            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func resetFlow() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.resetFlowState(clearCaptures: true)
            self.publishScanningState(
                faceDetected: false,
                stability: 0,
                hint: self.currentTarget?.instruction ?? "Align your face to begin."
            )
        }
    }

    func selectTargetArea(_ area: FaceScanArea) {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            guard !self.isCaptureInProgress else {
                return
            }

            guard self.remainingTargets.contains(area) else {
                return
            }

            self.currentTargetArea = area
            self.stableFrameCount = 0
            self.cooldownFrameCount = 0

            self.publishScanningState(
                faceDetected: false,
                stability: 0,
                hint: area.instruction
            )
        }
    }

    func availableFlashModes() -> [AVCaptureDevice.FlashMode] {
        guard let frontCamera = preferredFrontCamera(), frontCamera.hasFlash else {
            return [.off]
        }

        return [.off, .auto, .on]
    }

    func setFlashOption(_ option: FaceScanFlashOption) {
        selectedFlashOption = option
    }

    private func configureSession() throws {
        guard let frontCamera = preferredFrontCamera() else {
            throw FaceScanError.noCameraAvailable
        }

        let cameraInput = try AVCaptureDeviceInput(device: frontCamera)

        session.beginConfiguration()
        session.sessionPreset = .photo

        for input in session.inputs {
            session.removeInput(input)
        }

        for output in session.outputs {
            session.removeOutput(output)
        }

        if session.canAddInput(cameraInput) {
            session.addInput(cameraInput)
        } else {
            session.commitConfiguration()
            throw FaceScanError.unableToAddInput
        }

        guard session.canAddOutput(videoOutput) else {
            session.commitConfiguration()
            throw FaceScanError.unableToAddOutput
        }

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: analysisQueue)
        session.addOutput(videoOutput)

        guard session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            throw FaceScanError.unableToAddOutput
        }

        session.addOutput(photoOutput)
        configurePhotoOutput()
        configureOutputConnections()

        session.commitConfiguration()
        isSessionConfigured = true
    }

    private func configurePhotoOutput() {
        photoOutput.maxPhotoQualityPrioritization = .quality

        if photoOutput.isResponsiveCaptureSupported {
            photoOutput.isResponsiveCaptureEnabled = true
        }

        if photoOutput.isFastCapturePrioritizationSupported {
            photoOutput.isFastCapturePrioritizationEnabled = true
        }

        if photoOutput.isZeroShutterLagSupported {
            photoOutput.isZeroShutterLagEnabled = true
        }

        if photoOutput.isHighResolutionCaptureEnabled {
            photoOutput.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        }

        preparePhotoPipeline()
    }

    private func configureOutputConnections() {
        if let photoConnection = photoOutput.connection(with: .video), photoConnection.isVideoMirroringSupported {
            photoConnection.automaticallyAdjustsVideoMirroring = false
            photoConnection.isVideoMirrored = true
        }

        if let videoConnection = videoOutput.connection(with: .video), videoConnection.isVideoMirroringSupported {
            videoConnection.automaticallyAdjustsVideoMirroring = false
            videoConnection.isVideoMirrored = true
        }
    }

    private func makeCaptureSettings() -> AVCapturePhotoSettings {
        let settings: AVCapturePhotoSettings

        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            settings = AVCapturePhotoSettings()
        }

        let flashMode = selectedFlashOption.captureFlashMode

        if availableFlashModes().contains(flashMode) {
            settings.flashMode = flashMode
        } else {
            settings.flashMode = .off
        }

        settings.photoQualityPrioritization = .quality
        settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        return settings
    }

    private func preparePhotoPipeline() {
        let preparedSettings = makeCaptureSettings()
        photoOutput.setPreparedPhotoSettingsArray([preparedSettings], completionHandler: nil)
    }

    private func preferredFrontCamera() -> AVCaptureDevice? {
        if let trueDepth = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
            return trueDepth
        }

        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }

    private var currentTarget: FaceScanArea? {
        currentTargetArea
    }

    private func publishPreparingState() {
        let snapshot = FaceScanProgressSnapshot(
            status: .preparing,
            currentTarget: currentTarget,
            capturedAreas: capturedArtifacts.map(\.area),
            isFaceDetected: false,
            stabilityProgress: 0,
            hint: "Preparing camera session..."
        )

        progressSubject.send(snapshot)
    }

    private func publishScanningState(faceDetected: Bool, stability: Double, hint: String) {
        let snapshot = FaceScanProgressSnapshot(
            status: .scanning,
            currentTarget: currentTarget,
            capturedAreas: capturedArtifacts.map(\.area),
            isFaceDetected: faceDetected,
            stabilityProgress: max(0, min(1, stability)),
            hint: hint
        )

        progressSubject.send(snapshot)
    }

    private func publishError(_ message: String) {
        errorSubject.send(message)

        let snapshot = FaceScanProgressSnapshot(
            status: .failed(message),
            currentTarget: currentTarget,
            capturedAreas: capturedArtifacts.map(\.area),
            isFaceDetected: false,
            stabilityProgress: 0,
            hint: message
        )

        progressSubject.send(snapshot)
    }

    private func resetFlowState(clearCaptures: Bool) {
        remainingTargets = FaceScanArea.captureOrder
        currentTargetArea = remainingTargets.first
        stableFrameCount = 0
        cooldownFrameCount = 0
        isCaptureInProgress = false
        activePhotoCaptureDelegate = nil
        lastAnalyzedTimestamp = .zero

        if clearCaptures {
            capturedArtifacts.removeAll(keepingCapacity: true)
        }
    }

    private func shouldAnalyzeFrame(at timestamp: CMTime) -> Bool {
        guard timestamp.isValid else {
            return true
        }

        if lastAnalyzedTimestamp == .zero {
            lastAnalyzedTimestamp = timestamp
            return true
        }

        let delta = CMTimeSubtract(timestamp, lastAnalyzedTimestamp)
        guard delta.isValid, delta >= analysisInterval else {
            return false
        }

        lastAnalyzedTimestamp = timestamp
        return true
    }

    private func analyzeFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let request = VNDetectFaceLandmarksRequest()
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .leftMirrored,
            options: [:]
        )

        do {
            try imageRequestHandler.perform([request])
            let observation = request.results?
                .max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height })
            processObservation(observation)
        } catch {
            publishError(FaceScanError.detectionFailed.localizedDescription)
        }
    }

    private func processObservation(_ observation: VNFaceObservation?) {
        guard !isCaptureInProgress else {
            return
        }

        guard let target = currentTarget else {
            return
        }

        if cooldownFrameCount > 0 {
            cooldownFrameCount -= 1
            publishScanningState(faceDetected: true, stability: 0, hint: "Get ready for \(target.title).")
            return
        }

        let analysis = analyzer.analyze(observation: observation, target: target)

        if analysis.isTargetSatisfied {
            stableFrameCount += 1
        } else {
            stableFrameCount = 0
        }

        let stability = analysis.isTargetSatisfied
            ? Double(stableFrameCount) / Double(requiredStableFrames)
            : analysis.stabilityScore

        publishScanningState(
            faceDetected: analysis.faceDetected,
            stability: stability,
            hint: analysis.hint
        )

        if stableFrameCount >= requiredStableFrames {
            captureCurrentTarget(target)
        }
    }

    private func captureCurrentTarget(_ target: FaceScanArea) {
        guard !isCaptureInProgress else {
            return
        }

        guard session.isRunning else {
            publishError(FaceScanError.sessionNotRunning.localizedDescription)
            return
        }

        isCaptureInProgress = true
        stableFrameCount = 0

        let capturingSnapshot = FaceScanProgressSnapshot(
            status: .capturing(target),
            currentTarget: target,
            capturedAreas: capturedArtifacts.map(\.area),
            isFaceDetected: true,
            stabilityProgress: 1,
            hint: "Capturing \(target.title)..."
        )
        progressSubject.send(capturingSnapshot)

        let captureSettings = makeCaptureSettings()
        let delegate = FaceScanPhotoCaptureDelegate(owner: self, area: target)
        activePhotoCaptureDelegate = delegate
        photoOutput.capturePhoto(with: captureSettings, delegate: delegate)
    }

    fileprivate func handlePhotoCaptureResult(area: FaceScanArea, result: Result<Data, Error>) {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.activePhotoCaptureDelegate = nil
            self.isCaptureInProgress = false

            switch result {
            case .success(let imageData):
                let artifact = FaceScanCaptureArtifact(area: area, imageData: imageData, capturedAt: Date())
                self.capturedArtifacts.append(artifact)
                self.captureSubject.send(artifact)

                self.remainingTargets.removeAll(where: { $0 == area })

                if self.remainingTargets.isEmpty {
                    let completedArtifacts = self.capturedArtifacts

                    let completedSnapshot = FaceScanProgressSnapshot(
                        status: .completed,
                        currentTarget: nil,
                        capturedAreas: completedArtifacts.map(\.area),
                        isFaceDetected: false,
                        stabilityProgress: 1,
                        hint: "Face scan completed."
                    )
                    self.progressSubject.send(completedSnapshot)
                    self.completionSubject.send(completedArtifacts)
                    self.stopSession()
                    return
                }

                self.currentTargetArea = self.remainingTargets.first
                self.cooldownFrameCount = self.cooldownFrames

                let nextInstruction = self.currentTarget?.instruction ?? "Align your face to continue."
                self.publishScanningState(faceDetected: true, stability: 0, hint: nextInstruction)
            case .failure(let error):
                self.publishError(error.localizedDescription)
                self.publishScanningState(
                    faceDetected: true,
                    stability: 0,
                    hint: self.currentTarget?.instruction ?? "Try aligning your face again."
                )
            }
        }
    }
}

private final class FaceScanPhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    nonisolated(unsafe) private weak var owner: FaceScanSessionService?
    private let area: FaceScanArea

    init(owner: FaceScanSessionService, area: FaceScanArea) {
        self.owner = owner
        self.area = area
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            owner?.handlePhotoCaptureResult(area: area, result: .failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            owner?.handlePhotoCaptureResult(area: area, result: .failure(FaceScanSessionService.FaceScanError.captureFailed))
            return
        }

        owner?.handlePhotoCaptureResult(area: area, result: .success(data))
    }
}

extension FaceScanSessionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            guard self.authorizationStatus == .authorized, self.session.isRunning else {
                return
            }

            guard self.currentTarget != nil else {
                return
            }

            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            guard self.shouldAnalyzeFrame(at: timestamp) else {
                return
            }

            self.analyzeFrame(sampleBuffer)
        }
    }
}

extension FaceScanSessionService {
    enum FaceScanError: LocalizedError {
        case noCameraAvailable
        case unableToAddInput
        case unableToAddOutput
        case captureFailed
        case permissionDenied
        case sessionNotRunning
        case detectionFailed

        var errorDescription: String? {
            switch self {
            case .noCameraAvailable:
                return "No front camera device was found."
            case .unableToAddInput:
                return "The camera input could not be added."
            case .unableToAddOutput:
                return "The photo output could not be added."
            case .captureFailed:
                return "The photo could not be captured."
            case .permissionDenied:
                return "Camera permission is required to capture photos."
            case .sessionNotRunning:
                return "The camera session is not running."
            case .detectionFailed:
                return "Face detection failed. Please keep your face clearly visible."
            }
        }
    }
}
