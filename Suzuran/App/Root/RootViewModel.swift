import Foundation
import Combine

@MainActor
final class RootViewModel: ObservableObject {
    enum Phase: Equatable {
        case home
        case failed(AppError)
    }

    @Published private(set) var phase: Phase = .home

    let scanHistoryStore: ScanHistoryStore
    private let bootstrapper: AppBootstrapping
    private let homeSummaryViewModelFactory: () -> HomeSummaryViewModel
    private var hasStarted = false

    init(
        bootstrapper: AppBootstrapping,
        scanHistoryStore: ScanHistoryStore,
        homeSummaryViewModelFactory: @escaping () -> HomeSummaryViewModel
    ) {
        self.bootstrapper = bootstrapper
        self.scanHistoryStore = scanHistoryStore
        self.homeSummaryViewModelFactory = homeSummaryViewModelFactory
    }

    func makeHomeSummaryViewModel() -> HomeSummaryViewModel {
        homeSummaryViewModelFactory()
    }

    func start() {
        guard !hasStarted else {
            return
        }

        hasStarted = true

        Task {
            do {
                try await bootstrapper.bootstrap()
            } catch {
                phase = .failed(AppErrorMapper.map(error))
            }
        }
    }

    func retry() {
        phase = .home
        hasStarted = false
        start()
    }
}
