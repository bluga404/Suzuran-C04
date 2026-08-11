import SwiftUI

/// Main Onboarding View orchestrating:
/// 1. SplashView (Screen 1)
/// 2. Paged TabView for Screens 2, 3, and 4 (Page 1, Page 2, Page 3)
struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            if viewModel.currentStep == .splash {
                SplashView(onContinue: {
                    withAnimation(.easeInOut) {
                        viewModel.nextStep()
                    }
                })
                .transition(.opacity)
            } else {
                TabView(selection: $viewModel.currentStep) {
                    OnboardingPage1View()
                        .tag(OnboardingStep.page1)

                    OnboardingPage2View()
                        .tag(OnboardingStep.page2)

                    OnboardingPage3View(onStart: {
                        viewModel.completeOnboarding()
                    })
                    .tag(OnboardingStep.page3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .transition(.opacity)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel())
}
