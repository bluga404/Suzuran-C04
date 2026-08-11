import SwiftUI

/// Onboarding Page 2 (Screen 3): "Acne Needs More Than a Routine"
struct OnboardingPage2View: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section (52% screen height): Main Asset Illustration lowered slightly
                ZStack(alignment: .bottom) {
                    Color.white
                    Image("skincareRoutineConsistency")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height * 0.44)
                        .padding(.top, 36)
                        .padding(.bottom, 8)
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.52)

                // Bottom section (48% screen height): Text area with pure White-to-Black gradient
                ZStack(alignment: .top) {
                    LinearGradient(
                        colors: OnboardingStep.page2.gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)

                    VStack(spacing: 12) {
                        Text("Acne Needs More Than a Routine")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.12))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Text("Without the right plan, products, and consistency, progress can fade and the same cycle starts all over again")
                            .font(.body)
                            .foregroundStyle(Color(red: 0.3, green: 0.32, blue: 0.38))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.48)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingPage2View()
}
