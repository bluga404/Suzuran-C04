import AVFoundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class FaceScanViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case checkingPermission
        case requestingPermission
        case unavailable
        case denied
        case restricted
        case preparing
        case scanning
        case capturing(FaceScanArea)
        case completed
        case failed(String)
    }

    @Published private(set) var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published private(set) var state: State = .idle
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentTarget: FaceScanArea?
    @Published private(set) var guidanceText: String = "Align your face to begin."
    @Published private(set) var stabilityProgress: Double = 0
    @Published private(set) var capturedArtifacts: [FaceScanCaptureArtifact] = []
    @Published private(set) var capturedPreviewByArea: [FaceScanArea: UIImage] = [:]
    @Published private(set) var availableFlashOptions: [FaceScanFlashOption] = [.off]
    @Published var selectedFlashOption: FaceScanFlashOption = .off

    private let faceScanService: FaceScanSessionServicing
    private var cancellables = Set<AnyCancellable>()
    private var isRequestingPermission = false

    var session: AVCaptureSession {
        faceScanService.session
    }

    var captureOrder: [FaceScanArea] {
        FaceScanArea.captureOrder
    }

    var shouldShowSettingsButton: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var capturedCount: Int {
        capturedArtifacts.count
    }

    var totalCaptureCount: Int {
        captureOrder.count
    }

    var progressFraction: Double {
        let total = Double(max(totalCaptureCount, 1))
        return min(1, Double(capturedCount) / total)
    }

    var isScanningLive: Bool {
        switch state {
        case .preparing, .scanning, .capturing:
            return true
        default:
            return false
        }
    }

    var canRetake: Bool {
        state == .completed || !capturedArtifacts.isEmpty
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
        case .idle:
            return "FaceScan"
        case .checkingPermission, .requestingPermission:
            return "Preparing FaceScan"
        case .unavailable:
            return "FaceScan unavailable"
        case .denied, .restricted:
            return "FaceScan access blocked"
        case .preparing:
            return "Starting FaceScan"
        case .scanning:
            return "Scan in progress"
        case .capturing(let area):
            return "Capturing \(area.title)"
        case .completed:
            return "FaceScan completed"
        case .failed:
            return "Unable to start FaceScan"
        }
    }

    var messageText: String {
        switch state {
        case .idle:
            return "Follow the guide to capture all face regions."
        case .checkingPermission:
            return "Checking FaceScan permission."
        case .requestingPermission:
            return "Waiting for your FaceScan permission response."
        case .unavailable:
            return "This device does not support front camera capture."
        case .denied, .restricted:
            return "Open Settings and allow FaceScan access for Suzuran."
        case .preparing:
            return "Preparing a fast FaceScan preview."
        case .scanning, .capturing:
            return guidanceText
        case .completed:
            return "All required face areas have been captured."
        case .failed(let reason):
            return reason
        }
    }

    init(faceScanService: FaceScanSessionServicing) {
        self.faceScanService = faceScanService
        bindServiceEvents()
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
            if state != .completed {
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

    func retake() {
        capturedArtifacts = []
        capturedPreviewByArea = [:]
        errorMessage = nil
        guidanceText = "Align your face to begin."
        stabilityProgress = 0
        currentTarget = FaceScanArea.captureOrder.first
        refreshFlashOptions()
        faceScanService.resetFlow()
        startSessionIfNeeded()
    }

    func updateFlashOption(_ option: FaceScanFlashOption) {
        selectedFlashOption = option
        faceScanService.setFlashOption(option)
    }

    func selectTargetArea(_ area: FaceScanArea) {
        guard isScanningLive else {
            return
        }

        guard capturedPreviewByArea[area] == nil else {
            return
        }

        faceScanService.selectTargetArea(area)
    }

    func isAreaCaptured(_ area: FaceScanArea) -> Bool {
        capturedPreviewByArea[area] != nil
    }

    func isAreaSelectable(_ area: FaceScanArea) -> Bool {
        isScanningLive && !isAreaCaptured(area)
    }

    private func refreshAuthorizationStatus() {
        authorizationStatus = faceScanService.authorizationStatus

        switch authorizationStatus {
        case .authorized:
            if state != .completed {
                state = faceScanService.isSessionRunning ? .scanning : .checkingPermission
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

        guard state != .completed else {
            return
        }

        guard !faceScanService.isSessionRunning else {
            state = .scanning
            return
        }

        state = .preparing
        faceScanService.setFlashOption(selectedFlashOption)

        faceScanService.startSession { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.refreshFlashOptions()
                self.state = .scanning
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.state = .failed(error.localizedDescription)
            }
        }
    }

    private func stopSession() {
        faceScanService.stopSession()
    }

    private func refreshFlashOptions() {
        let options = faceScanService.availableFlashModes().map(FaceScanFlashOption.from)
        availableFlashOptions = options.isEmpty ? [.off] : options

        if !availableFlashOptions.contains(selectedFlashOption) {
            selectedFlashOption = .off
        }

        faceScanService.setFlashOption(selectedFlashOption)
    }

    private func bindServiceEvents() {
        faceScanService.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.applySnapshot(snapshot)
            }
            .store(in: &cancellables)

        faceScanService.capturePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] artifact in
                self?.capturedArtifacts.append(artifact)
                if let image = UIImage(data: artifact.imageData) {
                    self?.capturedPreviewByArea[artifact.area] = image
                }
            }
            .store(in: &cancellables)

        faceScanService.completionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] artifacts in
                self?.capturedArtifacts = artifacts
                self?.state = .completed
                self?.stabilityProgress = 1
            }
            .store(in: &cancellables)

        faceScanService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.errorMessage = message
            }
            .store(in: &cancellables)
    }

    private func applySnapshot(_ snapshot: FaceScanProgressSnapshot) {
        currentTarget = snapshot.currentTarget
        guidanceText = snapshot.hint
        stabilityProgress = snapshot.stabilityProgress

        switch snapshot.status {
        case .idle:
            if state != .completed {
                state = .idle
            }
        case .preparing:
            state = .preparing
        case .scanning:
            if state != .completed {
                state = .scanning
            }
        case .capturing(let area):
            state = .capturing(area)
        case .completed:
            state = .completed
        case .unavailable:
            state = .unavailable
        case .permissionDenied:
            state = .denied
        case .failed(let reason):
            state = .failed(reason)
            errorMessage = reason
        }
    }
}
