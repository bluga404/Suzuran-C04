import SwiftUI

/// Onboarding Page 2 (Screen 3): "Acne Needs More Than a Routine"
struct OnboardingPage2View: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            // Main Asset Illustration
            Image("skincareRoutineConsistency")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260, maxHeight: 260)
                .padding(.horizontal, 24)

            Spacer(minLength: 32)

            // Header & Description Section
            VStack(spacing: 12) {
                Text("Acne Needs More Than a Routine")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Without the right plan, products, and consistency, progress can fade  and the same cycle starts all over again")
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
    OnboardingPage2View()
}
