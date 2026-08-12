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

                        OnboardingPage4View()
                            .tag(OnboardingStep.page4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()

                    // Bottom Navigation Controls: 4 Dots & Get Started Button
                    VStack(spacing: AppSpacing.md) {
                        // Custom 4-dot Page Control
                        PageIndicatorView(
                            numberOfPages: 4,
                            currentPage: viewModel.currentStep.pageIndex,
                            activeColor: .black,
                            inactiveColor: Color.gray.opacity(0.3),
                            onSelectPage: { index in
                                withAnimation(.easeInOut) {
                                    switch index {
                                    case 0: viewModel.currentStep = .page1
                                    case 1: viewModel.currentStep = .page2
                                    case 2: viewModel.currentStep = .page3
                                    case 3: viewModel.currentStep = .page4
                                    default: break
                                    }
                                }
                            }
                        )

                        // Get Started Button
                        Button(action: {
                            withAnimation(.easeInOut) {
                                viewModel.nextStep()
                            }
                        }) {
                            Text("Get Started")
                                .font(Font.bodyLarge)
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(AppColor.buttonPrimaryPurple)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
                .transition(.opacity)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(initialStep: .page1))
}
