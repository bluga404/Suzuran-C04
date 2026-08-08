import SwiftUI

/// Main Onboarding View orchestrating the 5 screens in exact order:
/// 1. SplashView (Welcome)
/// 2. OnboardingPage1View ("Discover Your Skin")
/// 3. OnboardingPage2View ("Know Which of Your Skincare...")
/// 4. OnboardingPage3View ("See Progress & Save Your History")
/// 5. ChooseVisualizationView ("Choose Your Visualization")
struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            switch viewModel.currentStep {
            case .splash:
                SplashView(onContinue: {
                    withAnimation(.easeInOut) {
                        viewModel.nextStep()
                    }
                })

            case .discoverSkin:
                OnboardingPage1View(
                    onNext: {
                        withAnimation(.easeInOut) {
                            viewModel.nextStep()
                        }
                    },
                    onSkip: {
                        withAnimation(.easeInOut) {
                            viewModel.skipToVisualization()
                        }
                    }
                )

            case .matchSkincare:
                OnboardingPage2View(
                    onNext: {
                        withAnimation(.easeInOut) {
                            viewModel.nextStep()
                        }
                    },
                    onBack: {
                        withAnimation(.easeInOut) {
                            viewModel.previousStep()
                        }
                    },
                    onSkip: {
                        withAnimation(.easeInOut) {
                            viewModel.skipToVisualization()
                        }
                    }
                )

            case .saveHistory:
                OnboardingPage3View(
                    onNext: {
                        withAnimation(.easeInOut) {
                            viewModel.nextStep()
                        }
                    },
                    onBack: {
                        withAnimation(.easeInOut) {
                            viewModel.previousStep()
                        }
                    },
                    onSkip: {
                        withAnimation(.easeInOut) {
                            viewModel.skipToVisualization()
                        }
                    }
                )

            case .chooseVisualization:
                ChooseVisualizationView(
                    selectedGender: $viewModel.selectedGender,
                    onNext: {
                        viewModel.completeOnboarding()
                    },
                    onBack: {
                        withAnimation(.easeInOut) {
                            viewModel.previousStep()
                        }
                    }
                )
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel())
}
