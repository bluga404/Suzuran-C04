import Combine
import SwiftUI

final class OnboardingViewModel: ObservableObject {
    @Published var pageIndex = 0
    @Published var isLastPage = false

    private let appRouter: AppRouter
    private let pages: [OnboardingPage] = [
        .init(title: "Welcome to Suzuran", description: "A clean environment for your brightest ideas.", symbol: "leaf.fill"),
        .init(title: "Stay Focused", description: "Track your progress with calm, friendly design.", symbol: "clock.fill"),
        .init(title: "Pick up the flow", description: "Start with a guided setup and enjoy a better routine.", symbol: "sparkles")
    ]

    var currentPage: OnboardingPage {
        pages[pageIndex]
    }

    var pageCount: Int {
        pages.count
    }

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
        updateState()
    }

    func advancePage() {
        guard pageIndex < pages.count - 1 else {
            completeOnboarding()
            return
        }

        pageIndex += 1
        updateState()
    }

    func skipOnboarding() {
        completeOnboarding()
    }

    private func updateState() {
        isLastPage = pageIndex == pages.count - 1
    }

    private func completeOnboarding() {
        appRouter.completeOnboarding()
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let symbol: String
}
