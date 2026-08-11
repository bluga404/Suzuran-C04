import SwiftUI
import Combine

/// ViewModel managing the Onboarding flow state, transitions, and user choices.
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep
    @Published var selectedGender: Gender

    let onComplete: (Gender) -> Void

    init(
        initialStep: OnboardingStep = .splash,
        defaultGender: Gender = .female,
        onComplete: @escaping (Gender) -> Void = { _ in }
    ) {
        self.currentStep = initialStep
        self.selectedGender = defaultGender
        self.onComplete = onComplete
    }

    // MARK: - Navigation Actions

    func nextStep() {
        switch currentStep {
        case .splash:
            currentStep = .page1
        case .page1:
            currentStep = .page2
        case .page2:
            currentStep = .page3
        case .page3:
            completeOnboarding()
        }
    }

    func previousStep() {
        switch currentStep {
        case .splash:
            break
        case .page1:
            currentStep = .splash
        case .page2:
            currentStep = .page1
        case .page3:
            currentStep = .page2
        }
    }

    func completeOnboarding() {
        onComplete(selectedGender)
    }
}
