import Foundation
import Combine

@MainActor
final class RootViewModel: ObservableObject {
    enum Phase: Equatable {
        case onboarding
        case home
        case failed(AppError)
    }

    @Published private(set) var phase: Phase

    let scanHistoryStore: ScanHistoryStore
    private let bootstrapper: AppBootstrapping
    private let homeSummaryViewModelFactory: () -> HomeSummaryViewModel
    private let onboardingViewModelFactory: (@escaping (Gender) -> Void) -> OnboardingViewModel
    private var hasStarted = false

    init(
        bootstrapper: AppBootstrapping,
        scanHistoryStore: ScanHistoryStore,
        homeSummaryViewModelFactory: @escaping () -> HomeSummaryViewModel,
        onboardingViewModelFactory: @escaping (@escaping (Gender) -> Void) -> OnboardingViewModel = { onComplete in
            OnboardingViewModel(onComplete: onComplete)
        }
    ) {
        self.bootstrapper = bootstrapper
        self.scanHistoryStore = scanHistoryStore
        self.homeSummaryViewModelFactory = homeSummaryViewModelFactory
        self.onboardingViewModelFactory = onboardingViewModelFactory
        
        // HIG: Show onboarding only on the first launch
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        self.phase = hasSeenOnboarding ? .home : .onboarding
    }

    func makeHomeSummaryViewModel() -> HomeSummaryViewModel {
        homeSummaryViewModelFactory()
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        onboardingViewModelFactory { [weak self] gender in
            self?.completeOnboarding(gender: gender)
        }
    }

    func completeOnboarding(gender: Gender) {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        phase = .home
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
