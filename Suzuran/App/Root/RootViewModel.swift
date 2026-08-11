import Foundation
import Combine

@MainActor
final class RootViewModel: ObservableObject {
    enum Phase: Equatable {
<<<<<<< HEAD
        case report
        case failed(AppError)
    }

    @Published private(set) var phase: Phase = .report
=======
        case onboarding
        case home
        case failed(AppError)
    }

    @Published private(set) var phase: Phase
>>>>>>> a10bb3936580a6da0237730f7d536607f842fb57

    let scanHistoryStore: ScanHistoryStore
    private let bootstrapper: AppBootstrapping
<<<<<<< HEAD
    private var hasStarted = false

    init(
        bootstrapper: AppBootstrapping
    ) {
        self.bootstrapper = bootstrapper
=======
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
>>>>>>> a10bb3936580a6da0237730f7d536607f842fb57
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
        phase = .report
        hasStarted = false
        start()
    }
}
