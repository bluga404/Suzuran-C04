import AVFoundation
import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    let greeting = "Good Morning"
    let details = "Your daily focus starts here."
    let summary = HomeDashboardSummary(
        title: "Today",
        subtitle: "You have 3 focus sessions ready to start."
    )

    @Published private(set) var isPreparingFaceScan = false

    private let appRouter: AppRouter
    private let faceScanService: FaceScanSessionServicing

    init(appRouter: AppRouter, faceScanService: FaceScanSessionServicing) {
        self.appRouter = appRouter
        self.faceScanService = faceScanService
    }

    func openFaceScan() {
        let status = faceScanService.authorizationStatus

        switch status {
        case .authorized:
            isPreparingFaceScan = true
            faceScanService.startSession { [weak self] _ in
                guard let self = self else { return }
                self.isPreparingFaceScan = false
                self.appRouter.navigateToHomeRoute(.faceScan)
            }
        case .notDetermined:
            isPreparingFaceScan = true
            faceScanService.requestAccess { [weak self] granted in
                guard let self = self else { return }

                if granted {
                    self.faceScanService.startSession { [weak self] _ in
                        guard let self = self else { return }
                        self.isPreparingFaceScan = false
                        self.appRouter.navigateToHomeRoute(.faceScan)
                    }
                } else {
                    self.isPreparingFaceScan = false
                    self.appRouter.navigateToHomeRoute(.faceScan)
                }
            }
        case .denied, .restricted:
            appRouter.navigateToHomeRoute(.faceScan)
        @unknown default:
            appRouter.navigateToHomeRoute(.faceScan)
        }
    }

    func makeFaceScanViewModel() -> FaceScanViewModel {
        FaceScanViewModel(faceScanService: faceScanService)
    }
}
