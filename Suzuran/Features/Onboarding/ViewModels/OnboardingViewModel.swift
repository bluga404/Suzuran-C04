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
            currentStep = .discoverSkin
        case .discoverSkin:
            currentStep = .matchSkincare
        case .matchSkincare:
            currentStep = .saveHistory
        case .saveHistory:
            currentStep = .chooseVisualization
        case .chooseVisualization:
            completeOnboarding()
        }
    }

    func previousStep() {
        switch currentStep {
        case .splash:
            break
        case .discoverSkin:
            currentStep = .splash
        case .matchSkincare:
            currentStep = .discoverSkin
        case .saveHistory:
            currentStep = .matchSkincare
        case .chooseVisualization:
            currentStep = .saveHistory
        }
    }

    func skipToVisualization() {
        currentStep = .chooseVisualization
    }

    func completeOnboarding() {
        onComplete(selectedGender)
    }
}
