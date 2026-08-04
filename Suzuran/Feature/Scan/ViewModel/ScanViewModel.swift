import Combine
import UIKit

@MainActor
final class ScanViewModel: ObservableObject {
    enum Phase {
        case idle
        case camera
        case processing
        case result
    }

    enum PermissionState {
        case undetermined
        case requesting
        case granted
        case denied
    }

    @Published var phase: Phase = .idle
    @Published var permissionState: PermissionState = .undetermined
    @Published var capturedImage: UIImage?
    @Published var detections: [AcneDetection] = []
    @Published var result: PredictionResult?
    @Published var isProcessing = false
    @Published var errorMessage: String?

    let cameraService = CameraService()
    private let predictionService = PredictionService()

    func startCamera() async {
        permissionState = .requesting
        let granted = await cameraService.requestPermission()
        permissionState = granted ? .granted : .denied
        guard granted else { return }

        cameraService.startSession()
        phase = .camera
    }

    func stopCamera() {
        cameraService.stopSession()
    }

    func toggleCamera() {
        cameraService.toggleCamera()
    }

    func capturePhoto() {
        guard permissionState == .granted else { return }

        cameraService.capturePhoto { [weak self] image in
            Task { @MainActor in
                self?.processCapturedImage(image)
            }
        }
    }

    func handlePickedImage(_ data: Data) {
        guard let image = UIImage(data: data) else {
            errorMessage = "The selected image could not be loaded."
            return
        }
        processCapturedImage(image)
    }

    func reset() {
        stopCamera()
        phase = .idle
        permissionState = .undetermined
        capturedImage = nil
        detections = []
        result = nil
        isProcessing = false
        errorMessage = nil
    }

    private func processCapturedImage(_ image: UIImage) {
        stopCamera()
        capturedImage = image
        detections = []
        result = nil
        errorMessage = nil
        phase = .processing
        runInference(on: image)
    }

    private func runInference(on image: UIImage) {
        isProcessing = true

        Task {
            do {
                let detections = try await Task.detached(priority: .userInitiated) {
                    try self.predictionService.predict(image)
                }.value
                self.detections = detections
                self.result = self.predictionService.topPrediction(from: detections, image: image)
            } catch {
                self.errorMessage = error.localizedDescription
            }

            self.isProcessing = false
            self.phase = .result
        }
    }
}
