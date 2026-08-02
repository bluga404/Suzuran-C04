@preconcurrency import AVFoundation
import UIKit
import CoreImage
import Combine

final class FaceScanSessionService: NSObject, FaceScanSessionServicing {
    private let sessionQueue = DispatchQueue(label: "com.suzuran.facescan.session", qos: .userInitiated)
    private(set) lazy var session: AVCaptureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var isSessionConfigured = false
    private var preparedCaptureSettings = AVCapturePhotoSettings()
    nonisolated(unsafe) fileprivate var currentPhotoCaptureDelegate: PhotoCaptureDelegate?

    private let lightQualitySubject = CurrentValueSubject<FaceScanLightQuality, Never>(.unknown)
    var lightQualityPublisher: AnyPublisher<FaceScanLightQuality, Never> {
        lightQualitySubject.eraseToAnyPublisher()
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

        // Video output for light estimation
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
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

// MARK: - Light estimation using video frames
extension FaceScanSessionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Use Core Image's CIAreaAverage to compute average color (luminance)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        let context = CIContext(options: nil)

        guard let filter = CIFilter(name: "CIAreaAverage") else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)

        guard let outputImage = filter.outputImage else { return }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        // Convert to luminance (0.0 - 1.0)
        let r = Double(bitmap[0]) / 255.0
        let g = Double(bitmap[1]) / 255.0
        let b = Double(bitmap[2]) / 255.0

        // Standard relative luminance
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b

        let newQuality: FaceScanLightQuality
        if luminance < 0.18 {
            newQuality = .low
        } else if luminance < 0.5 {
            newQuality = .adequate
        } else {
            newQuality = .good
        }

        // Only publish on change
        if lightQualitySubject.value != newQuality {
            lightQualitySubject.send(newQuality)
        }
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
