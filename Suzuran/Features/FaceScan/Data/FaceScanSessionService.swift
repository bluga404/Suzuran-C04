@preconcurrency import AVFoundation
import UIKit

final class FaceScanSessionService: NSObject, FaceScanSessionServicing {
    private let sessionQueue = DispatchQueue(label: "com.suzuran.facescan.session", qos: .userInitiated)
    private(set) lazy var session: AVCaptureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var isSessionConfigured = false
    private var preparedCaptureSettings = AVCapturePhotoSettings()
    nonisolated(unsafe) fileprivate var currentPhotoCaptureDelegate: PhotoCaptureDelegate?

    var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    var isCameraAvailable: Bool {
        preferredFrontCamera() != nil
    }

    var isSessionRunning: Bool {
        session.isRunning
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
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }

            self.preparePhotoPipeline()

            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func availableFlashModes() -> [AVCaptureDevice.FlashMode] {
        guard let frontCamera = preferredFrontCamera(), frontCamera.hasFlash else {
            return [.off]
        }

        return [.off, .auto, .on]
    }

    func capturePhoto(
        flashMode: AVCaptureDevice.FlashMode,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            guard self.authorizationStatus == .authorized else {
                DispatchQueue.main.async {
                    completion(.failure(FaceScanError.permissionDenied))
                }
                return
            }

            guard self.session.isRunning else {
                DispatchQueue.main.async {
                    completion(.failure(FaceScanError.sessionNotRunning))
                }
                return
            }

            guard self.currentPhotoCaptureDelegate == nil else {
                DispatchQueue.main.async {
                    completion(.failure(FaceScanError.captureInProgress))
                }
                return
            }

            let settings = self.makeCaptureSettings(flashMode: flashMode)

            let delegate = PhotoCaptureDelegate(owner: self) { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }

            self.currentPhotoCaptureDelegate = delegate

            guard self.photoOutput.connection(with: .video) != nil else {
                self.currentPhotoCaptureDelegate = nil
                DispatchQueue.main.async {
                    completion(.failure(FaceScanError.captureFailed))
                }
                return
            }

            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
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

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            configurePhotoOutput()
        } else {
            session.commitConfiguration()
            throw FaceScanError.unableToAddOutput
        }

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
    }

    private func makeCaptureSettings(flashMode: AVCaptureDevice.FlashMode) -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()

        if availableFlashModes().contains(flashMode) {
            settings.flashMode = flashMode
        } else {
            settings.flashMode = .off
        }

        settings.photoQualityPrioritization = .balanced
        return settings
    }

    private func preparePhotoPipeline() {
        preparedCaptureSettings = makeCaptureSettings(flashMode: .off)
        photoOutput.setPreparedPhotoSettingsArray([preparedCaptureSettings], completionHandler: nil)
    }

    private func preferredFrontCamera() -> AVCaptureDevice? {
        if let trueDepth = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
            return trueDepth
        }

        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    nonisolated(unsafe) private weak var owner: FaceScanSessionService?
    nonisolated(unsafe) private let completion: (Result<UIImage, Error>) -> Void

    init(owner: FaceScanSessionService, completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.owner = owner
        self.completion = completion
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        defer {
            owner?.currentPhotoCaptureDelegate = nil
        }

        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            completion(.failure(FaceScanSessionService.FaceScanError.captureFailed))
            return
        }

        completion(.success(image))
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
        case captureInProgress

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
            case .captureInProgress:
                return "A photo capture is already in progress."
            }
        }
    }
}
