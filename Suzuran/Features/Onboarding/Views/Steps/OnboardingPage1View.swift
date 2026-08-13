import SwiftUI

/// Onboarding OS1: Welcome to Your Digital Mirror
struct OnboardingPage1View: View {
    var body: some View {
        OnboardingPageView(
            imageName: "OS1Suzuran",
            title: "Welcome to Your Digital Mirror",
            subtitle: "Discover your acne types and get a measurable skin score"
        )
    }
}

#Preview {
    OnboardingPage1View()
}
