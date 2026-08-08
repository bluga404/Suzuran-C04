import SwiftUI

/// Page indicator rendering 3 dots with active step highlighting.
struct OnboardingPageIndicator: View {
    let currentPage: Int // 1, 2, or 3
    var totalPages: Int = 3

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalPages, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? Color.black : Color(white: 0.8))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        OnboardingPageIndicator(currentPage: 1)
        OnboardingPageIndicator(currentPage: 2)
        OnboardingPageIndicator(currentPage: 3)
    }
}
