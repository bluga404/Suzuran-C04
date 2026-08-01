import Combine
import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    @Published private(set) var rootRoute: AppRoute = .onboarding
    @Published var homePath = NavigationPath()

    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted = false

    init() {
        rootRoute = isOnboardingCompleted ? .home : .onboarding
    }

    func completeOnboarding() {
        isOnboardingCompleted = true
        homePath = NavigationPath()
        rootRoute = .home
    }

    func restartOnboarding() {
        isOnboardingCompleted = false
        homePath = NavigationPath()
        rootRoute = .onboarding
    }

    func navigateToHomeRoute(_ route: HomeRoute) {
        homePath.append(route)
    }
}
