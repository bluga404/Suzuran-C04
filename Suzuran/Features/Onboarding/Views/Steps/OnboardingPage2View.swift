import SwiftUI

/// Onboarding OS2: Scan to Understand Your Skin
struct OnboardingPage2View: View {
    var body: some View {
        OnboardingPageView(
            imageName: "OS2Suzuran",
            title: "Scan to Understand Your Skin",
            subtitle: "Each scan gives you accurate data to analyze your acne condition"
        )
    }
}

#Preview {
    OnboardingPage2View()
}
