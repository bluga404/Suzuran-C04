import Foundation
import Combine

@MainActor
final class RootViewModel: ObservableObject {
    enum Phase: Equatable {
        case onboarding
        case home
        case failed(AppError)
    }

    @Published private(set) var phase: Phase = .onboarding

    private let bootstrapper: AppBootstrapping
    private let homeViewModelFactory: () -> HomeViewModel
    private let onboardingViewModelFactory: (@escaping (Gender) -> Void) -> OnboardingViewModel
    private var hasStarted = false

    init(
        bootstrapper: AppBootstrapping,
        homeViewModelFactory: @escaping () -> HomeViewModel,
        onboardingViewModelFactory: @escaping (@escaping (Gender) -> Void) -> OnboardingViewModel = { onComplete in
            OnboardingViewModel(onComplete: onComplete)
        }
    ) {
        self.bootstrapper = bootstrapper
        self.homeViewModelFactory = homeViewModelFactory
        self.onboardingViewModelFactory = onboardingViewModelFactory
    }

    func makeHomeViewModel() -> HomeViewModel {
        homeViewModelFactory()
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        onboardingViewModelFactory { [weak self] _ in
            self?.completeOnboarding()
        }
    }

    func completeOnboarding() {
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
