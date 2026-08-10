import SwiftUI

/// App color tokens. Uses adaptive system colors so elements automatically adapt to Light and Dark mode.
enum AppColor {
    static let backgroundPrimary = Color(.systemGroupedBackground)
    // History-compare adaptive colors (dark mode ready)
    static let surfacePrimary = Color(.secondarySystemGroupedBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let accentPrimary = Color.primary
    static let accentDanger = Color(red: 0.74, green: 0.20, blue: 0.20)
    static let borderSubtle = Color(.separator)

    // Homepage score severity colors
    static let scoreVeryGood = Color.green
    static let scoreGood = Color(red: 0.6, green: 0.8, blue: 0.2) // Yellow-green
    static let scoreModerate = Color.orange
    static let scoreLow = Color.red
    static let scoreVeryLow = Color(red: 0.55, green: 0.0, blue: 0.0) // Dark red
}
