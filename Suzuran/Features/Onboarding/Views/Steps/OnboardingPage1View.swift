import SwiftUI

/// Onboarding Page 1 (Screen 2): "The problem with treating Acne"
struct OnboardingPage1View: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            // Main Asset Illustration
            Image("acneProgressUncertainty")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260, maxHeight: 260)
                .padding(.horizontal, 24)

            Spacer(minLength: 32)

            // Header & Description Section
            VStack(spacing: 12) {
                Text("The problem with treating Acne")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("No changes? Hard to tell? Knowing whether all the effort is actually making a difference can be difficult.")
                    .font(.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Invisible balancing space matching Page 3 Start button
            Color.clear
                .frame(height: 52)
                .padding(.bottom, 40) // Space for native page indicator
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
    }
}

#Preview {
    OnboardingPage1View()
}
