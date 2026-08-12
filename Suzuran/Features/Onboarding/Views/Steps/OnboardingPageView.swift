import SwiftUI

/// Reusable Onboarding Page View matching OS1..OS4 designs.
/// Features top illustration asset, centered bold title, description text, and clean white background.
struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Illustration section (55% screen height)
                VStack {
                    Spacer(minLength: 20)
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, 40)
                    Spacer(minLength: 10)
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.55)

                // Text Content section (45% screen height)
                VStack(spacing: AppSpacing.sm) {
                    Text(title)
                        .font(Font.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)

                    Text(subtitle)
                        .font(Font.labelRegular)
                        .foregroundStyle(AppColor.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, AppSpacing.xl)

                    Spacer()
                }
                .padding(.top, AppSpacing.md)
                .frame(width: geometry.size.width, height: geometry.size.height * 0.45)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    OnboardingPageView(
        imageName: "OS1Suzuran",
        title: "Welcome to Your Digital Mirror",
        subtitle: "Discover your acne types and get a measurable skin score"
    )
}
