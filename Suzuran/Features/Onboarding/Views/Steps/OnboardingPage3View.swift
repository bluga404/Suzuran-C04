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
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                Text("Suzuran helps you understand your acne, make better choices about skincare ingredients, and finally find what works")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Page Indicator
            OnboardingPageIndicator(currentPage: 3)
                .padding(.bottom, 24)

            // Start Button with hex color 5B4EB1
            Button(action: onStart) {
                Text("Start")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(Color(red: 0x5B / 255.0, green: 0x4E / 255.0, blue: 0xB1 / 255.0))
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    OnboardingPage3View(onStart: {})
}
