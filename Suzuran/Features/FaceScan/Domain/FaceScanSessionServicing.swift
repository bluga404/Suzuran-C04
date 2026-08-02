import AVFoundation
import Combine

protocol FaceScanSessionServicing: AnyObject {
    var session: AVCaptureSession { get }
    var authorizationStatus: AVAuthorizationStatus { get }
    var isCameraAvailable: Bool { get }
    var isSessionRunning: Bool { get }
    var progressPublisher: AnyPublisher<FaceScanProgressSnapshot, Never> { get }
    var capturePublisher: AnyPublisher<FaceScanCaptureArtifact, Never> { get }
    var completionPublisher: AnyPublisher<[FaceScanCaptureArtifact], Never> { get }
    var errorPublisher: AnyPublisher<String, Never> { get }

    func requestAccess(_ completion: @escaping (Bool) -> Void)
    func startSession(completion: @escaping (Result<Void, Error>) -> Void)
    func stopSession()
    func resetFlow()
    func selectTargetArea(_ area: FaceScanArea)
    func availableFlashModes() -> [AVCaptureDevice.FlashMode]
    func setFlashOption(_ option: FaceScanFlashOption)
}
