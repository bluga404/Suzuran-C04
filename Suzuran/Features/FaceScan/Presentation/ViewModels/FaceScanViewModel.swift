import AVFoundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class FaceScanViewModel: ObservableObject {
    enum State: Equatable {
        case checkingPermission
        case requestingPermission
        case unavailable
        case denied
        case restricted
        case startingSession
        case previewReady
        case captureInProgress
        case captured
        case failed(String)
    }

    @Published private(set) var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published private(set) var state: State = .checkingPermission
    @Published private(set) var capturedImage: UIImage?
    @Published private(set) var errorMessage: String?
    @Published private(set) var availableFlashOptions: [FaceScanFlashOption] = [.off]
    @Published var selectedFlashOption: FaceScanFlashOption = .off

    private let faceScanService: FaceScanSessionServicing
    private var isRequestingPermission = false
    private var isStartingSession = false
    private var isCapturingPhoto = false

    var session: AVCaptureSession {
        faceScanService.session
    }

    var canCapture: Bool {
        state == .previewReady
    }

    var shouldShowSettingsButton: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var hasCapturedImage: Bool {
        capturedImage != nil
    }

    var isFlashAvailable: Bool {
        availableFlashOptions.count > 1
    }

    var isInFailureState: Bool {
        if case .failed = state {
            return true
        }

        return false
    }

    var titleText: String {
        switch state {
        case .checkingPermission, .requestingPermission:
            return "Preparing FaceScan"
        case .unavailable:
            return "FaceScan unavailable"
        case .denied, .restricted:
            return "FaceScan access blocked"
        case .startingSession:
            return "Starting FaceScan"
        case .previewReady, .captureInProgress:
            return "Ready to capture"
        case .captured:
            return "FaceScan captured"
        case .failed:
            return "Unable to start FaceScan"
        }
    }

    var messageText: String {
        switch state {
        case .checkingPermission:
            return "Checking FaceScan permission."
        case .requestingPermission:
            return "Waiting for your FaceScan permission response."
        case .unavailable:
            return "This device does not support front camera capture."
        case .denied, .restricted:
            return "Open Settings and allow FaceScan access for Suzuran."
        case .startingSession:
            return "Preparing a fast FaceScan preview."
        case .previewReady:
            return "Align your face and capture your scan."
        case .captureInProgress:
            return "Capturing image..."
        case .captured:
            return "Review your captured image, or take another one."
        case .failed(let reason):
            return reason
        }
    }

    var captureButtonTitle: String {
        state == .captureInProgress ? "Capturing..." : "Capture FaceScan"
    }

    init(faceScanService: FaceScanSessionServicing) {
        self.faceScanService = faceScanService
    }

    func onAppear() {
        refreshFlashOptions()
        refreshAuthorizationStatus()

        guard faceScanService.isCameraAvailable else {
            state = .unavailable
            return
        }

        switch authorizationStatus {
        case .authorized:
            startSessionIfNeeded()
        case .notDetermined:
            requestPermissionAndStartIfNeeded()
        case .denied:
            state = .denied
        case .restricted:
            state = .restricted
        @unknown default:
            state = .failed("Unknown camera authorization state.")
        }
    }

    func onDisappear() {
        stopSession()
    }

    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            refreshAuthorizationStatus()
            if capturedImage == nil {
                startSessionIfNeeded()
            }
        case .inactive, .background:
            stopSession()
        @unknown default:
            break
        }
    }

    func requestPermissionAndStartIfNeeded() {
        guard faceScanService.isCameraAvailable else {
            state = .unavailable
            return
        }

        guard authorizationStatus == .notDetermined, !isRequestingPermission else {
            return
        }

        isRequestingPermission = true
        state = .requestingPermission

        faceScanService.requestAccess { [weak self] granted in
            guard let self = self else { return }
            self.isRequestingPermission = false
            self.refreshAuthorizationStatus()

            if granted {
                self.startSessionIfNeeded()
            } else {
                self.state = self.authorizationStatus == .restricted ? .restricted : .denied
            }
        }
    }

    func retry() {
        errorMessage = nil
        refreshAuthorizationStatus()

        switch authorizationStatus {
        case .authorized:
            startSessionIfNeeded()
        case .notDetermined:
            requestPermissionAndStartIfNeeded()
        case .denied:
            state = .denied
        case .restricted:
            state = .restricted
        @unknown default:
            state = .failed("Unknown camera authorization state.")
        }
    }

    func captureFaceScan() {
        guard canCapture, !isCapturingPhoto else {
            return
        }

        isCapturingPhoto = true
        errorMessage = nil
        state = .captureInProgress

        faceScanService.capturePhoto(flashMode: selectedFlashOption.captureFlashMode) { [weak self] result in
            guard let self = self else { return }
            self.isCapturingPhoto = false

            switch result {
            case .success(let image):
                self.capturedImage = image
                self.state = .captured
                self.stopSession()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.state = self.faceScanService.isSessionRunning ? .previewReady : .failed(error.localizedDescription)
            }
        }
    }

    func retake() {
        capturedImage = nil
        errorMessage = nil
        refreshFlashOptions()
        startSessionIfNeeded()
    }

    private func refreshAuthorizationStatus() {
        authorizationStatus = faceScanService.authorizationStatus

        switch authorizationStatus {
        case .authorized:
            if capturedImage == nil {
                state = faceScanService.isSessionRunning ? .previewReady : .startingSession
            }
        case .notDetermined:
            state = .checkingPermission
        case .denied:
            state = .denied
        case .restricted:
            state = .restricted
        @unknown default:
            state = .failed("Unknown camera authorization state.")
        }
    }

    private func startSessionIfNeeded() {
        guard faceScanService.isCameraAvailable else {
            state = .unavailable
            return
        }

        guard authorizationStatus == .authorized else {
            refreshAuthorizationStatus()
            return
        }

        guard capturedImage == nil else {
            return
        }

        guard !faceScanService.isSessionRunning, !isStartingSession else {
            state = .previewReady
            return
        }

        isStartingSession = true
        state = .startingSession

        faceScanService.startSession { [weak self] result in
            guard let self = self else { return }
            self.isStartingSession = false

            switch result {
            case .success:
                self.refreshFlashOptions()
                self.state = .previewReady
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.state = .failed(error.localizedDescription)
            }
        }
    }

    private func stopSession() {
        faceScanService.stopSession()
        isStartingSession = false
        isCapturingPhoto = false
    }

    private func refreshFlashOptions() {
        let options = faceScanService.availableFlashModes().map(FaceScanFlashOption.from)
        availableFlashOptions = options.isEmpty ? [.off] : options

        if !availableFlashOptions.contains(selectedFlashOption) {
            selectedFlashOption = .off
        }
    }
}
