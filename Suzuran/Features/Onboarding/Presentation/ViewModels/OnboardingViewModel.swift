import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var pageIndex = 0

    private let appRouter: AppRouter
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Suzuran",
            description: "A calm space for your daily focus and reflections.",
            symbolName: "leaf.fill"
        ),
        OnboardingPage(
            title: "Capture FaceScan",
            description: "Use a fast, guided face scan flow when you need it.",
            symbolName: "camera.viewfinder"
        ),
        OnboardingPage(
            title: "Stay in Flow",
            description: "Simple navigation and clear status feedback at every step.",
            symbolName: "sparkles"
        )
    ]

    var currentPage: OnboardingPage {
        pages[pageIndex]
    }

    var isLastPage: Bool {
        pageIndex == pages.count - 1
    }

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func advance() {
        guard !isLastPage else {
            appRouter.completeOnboarding()
            return
        }

        pageIndex += 1
    }

    func skip() {
        appRouter.completeOnboarding()
    }
}
