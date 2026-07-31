import Combine
import SwiftUI

final class AppRouter: ObservableObject {
    @Published private(set) var currentRoute: AppRoute = .onboarding
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted = false

    init() {
        currentRoute = isOnboardingCompleted ? .home : .onboarding
    }

    func completeOnboarding() {
        isOnboardingCompleted = true
        currentRoute = .home
    }
}
