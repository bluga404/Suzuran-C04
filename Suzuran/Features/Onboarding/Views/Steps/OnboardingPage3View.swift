import SwiftUI

/// Onboarding Page 3: "See Progress & Save Your History" (Image 4)
struct OnboardingPage3View: View {
    let onNext: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.black)
                }

                Spacer()

                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.black)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer(minLength: 16)

            // Header Section
            VStack(spacing: 12) {
                Text("See Progress & Save Your\nHistory")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                Text("Compare your skin side-by-side and access comprehensive reports anytime. End your journey to save it as a history, then start a new one to test a different routine!")
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 32)

            // Main Face Scan Placeholder Illustration
            FaceScanPlaceholderView(size: 220)

            Spacer(minLength: 40)

            // Page Indicator
            OnboardingPageIndicator(currentPage: 3)
                .padding(.bottom, 24)

            // Bottom Action Button
            Button(action: onNext) {
                Text("Let’s Get Started")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(Color(white: 0.6))
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    OnboardingPage3View(onNext: {}, onBack: {}, onSkip: {})
}
