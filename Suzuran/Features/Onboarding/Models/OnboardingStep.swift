import Foundation

/// Represents the sequential pages in the onboarding flow.
enum OnboardingStep: Int, CaseIterable, Comparable {
    case splash = 0
    case page1 = 1
    case page2 = 2
    case page3 = 3

    static func < (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
