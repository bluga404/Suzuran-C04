import SwiftUI

/// Onboarding Page 2: "Know Which of Your Skincare Match Your Acne Type" (Image 3)
struct OnboardingPage2View: View {
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
                Text("Know Which of Your Skincare\nMatch Your Acne Type")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                Text("Log the products you use in this journey. We'll analyze if your skincare have ingredients that is a right match for the acne you're targeting right now.")
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
            OnboardingPageIndicator(currentPage: 2)
                .padding(.bottom, 24)

            // Bottom Action Button
            Button(action: onNext) {
                Text("Next")
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
    OnboardingPage2View(onNext: {}, onBack: {}, onSkip: {})
}
