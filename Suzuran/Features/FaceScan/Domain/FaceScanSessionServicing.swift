import AVFoundation
import UIKit

protocol FaceScanSessionServicing: AnyObject {
    var session: AVCaptureSession { get }
    var authorizationStatus: AVAuthorizationStatus { get }
    var isCameraAvailable: Bool { get }
    var isSessionRunning: Bool { get }

    func requestAccess(_ completion: @escaping (Bool) -> Void)
    func startSession(completion: @escaping (Result<Void, Error>) -> Void)
    func stopSession()
    func availableFlashModes() -> [AVCaptureDevice.FlashMode]
    func capturePhoto(
        flashMode: AVCaptureDevice.FlashMode,
        completion: @escaping (Result<UIImage, Error>) -> Void
    )
}
