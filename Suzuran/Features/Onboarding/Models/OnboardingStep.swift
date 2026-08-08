import Foundation

/// Represents the sequential pages in the onboarding flow.
enum OnboardingStep: Int, CaseIterable, Comparable {
    case splash = 0
    case discoverSkin = 1
    case matchSkincare = 2
    case saveHistory = 3
    case chooseVisualization = 4

    static func < (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
