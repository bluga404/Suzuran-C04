import SwiftUI

/// Represents the sequential pages in the onboarding flow.
enum OnboardingStep: Int, CaseIterable, Comparable {
    case splash = 0
    case page1 = 1
    case page2 = 2
    case page3 = 3

    static func < (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Page index (0-based) for non-splash onboarding steps.
    var pageIndex: Int {
        switch self {
        case .splash: return 0
        case .page1: return 0
        case .page2: return 1
        case .page3: return 2
        }
    }

    /// Pure white-to-black gradient colors across all onboarding pages.
    var gradientColors: [Color] {
        return [Color.white, Color.black]
    }
}
