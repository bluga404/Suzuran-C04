import SwiftUI

/// Onboarding Page 1: "Discover Your Skin" (Image 2)
struct OnboardingPage1View: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
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
                Text("Discover Your Skin")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                descriptionText
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 24)

            // Main Face Scan Placeholder Illustration
            FaceScanPlaceholderView(size: 200)

            Spacer(minLength: 28)

            // 3 Sub-feature Icons (Face Scan, Detect Acne, Set Baseline)
            HStack(spacing: 24) {
                subFeatureItem(title: "Face Scan")
                subFeatureItem(title: "Detect Acne")
                subFeatureItem(title: "Set Baseline")
            }

            Spacer(minLength: 24)

            // Page Indicator
            OnboardingPageIndicator(currentPage: 1)
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

    private var descriptionText: Text {
        Text("Take a quick ")
            .font(.system(size: 14))
            .foregroundColor(.black)
        + Text("private")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.black)
        + Text(" scan to identify your current acne condition. This scan will be the starting point (baseline) for your new recovery journey.")
            .font(.system(size: 14))
            .foregroundColor(.black)
    }

    private func subFeatureItem(title: String) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(white: 0.8))
                .frame(width: 52, height: 52)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.black)
        }
    }
}

#Preview {
    OnboardingPage1View(onNext: {}, onSkip: {})
}
