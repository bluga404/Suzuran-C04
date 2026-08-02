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

    private let appRouter: AppRouter
    private let faceScanService: FaceScanSessionServicing

    init(appRouter: AppRouter, faceScanService: FaceScanSessionServicing) {
        self.appRouter = appRouter
        self.faceScanService = faceScanService
    }

    func openFaceScan() {
        appRouter.navigateToHomeRoute(.faceScan)
    }

    func makeFaceScanViewModel() -> FaceScanViewModel {
        FaceScanViewModel(faceScanService: faceScanService)
    }
}
