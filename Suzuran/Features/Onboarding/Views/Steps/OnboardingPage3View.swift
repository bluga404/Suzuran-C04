import SwiftUI

/// Onboarding Page 3 (Screen 4): "Ready to See Where It’s Going?"
struct OnboardingPage3View: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            // Main Asset Illustration
            Image("faceScanProgressTracking")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260, maxHeight: 260)
                .padding(.horizontal, 24)

            Spacer(minLength: 32)

            // Header & Description Section
            VStack(spacing: 12) {
                Text("Ready to See Where It’s Going?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Suzuran helps you understand your acne, make better choices about skincare ingredients, and finally find what works")
                    .font(.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Start Button
            Button(action: onStart) {
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
            .padding(.bottom, 40) // Space for native page indicator alignment
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }
}

#Preview {
    OnboardingPage3View(onStart: {})
}
