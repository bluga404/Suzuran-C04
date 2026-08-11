import SwiftUI

/// Main Onboarding View orchestrating:
/// 1. SplashView (Screen 1)
/// 2. Paged TabView with custom page control dots & sticky "Start" button for Pages 1, 2, and 3
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
                ZStack(alignment: .bottom) {
                    TabView(selection: $viewModel.currentStep) {
                        OnboardingPage1View()
                            .tag(OnboardingStep.page1)

                        OnboardingPage2View()
                            .tag(OnboardingStep.page2)

                        OnboardingPage3View()
                            .tag(OnboardingStep.page3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()

                    // Bottom Navigation Controls: Custom Page Control & Start Button
                    VStack(spacing: 20) {
                        // Custom Page Control Dots
                        PageIndicatorView(
                            numberOfPages: 3,
                            currentPage: viewModel.currentStep.pageIndex,
                            onSelectPage: { index in
                                withAnimation(.easeInOut) {
                                    switch index {
                                    case 0: viewModel.currentStep = .page1
                                    case 1: viewModel.currentStep = .page2
                                    case 2: viewModel.currentStep = .page3
                                    default: break
                                    }
                                }
                            }
                        )

                        // Start Button present on all pages
                        Button(action: {
                            withAnimation(.easeInOut) {
                                viewModel.completeOnboarding()
                            }
                        }) {
                            Text("Start")
                                .font(.headline)
                                .foregroundStyle(Color(UIColor.systemBackground))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                               .background(
                                   Capsule()
                                       .fill(AppColor.accentPrimary)
                               )
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 24)
                }
                .ignoresSafeArea(edges: .top)
                .transition(.opacity)
            }
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(initialStep: .page1))
}
