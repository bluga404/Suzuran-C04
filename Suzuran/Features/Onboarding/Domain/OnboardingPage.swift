import Foundation

struct OnboardingPage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let symbolName: String
}
