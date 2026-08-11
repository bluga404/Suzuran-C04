import SwiftUI

/// App color tokens. Uses adaptive system colors so elements automatically adapt to Light and Dark mode.
enum AppColor {
<<<<<<< HEAD
    static let backgroundPrimary = Color.white
    static let surfacePrimary = Color.white
    static let textPrimary = Color(red: 0.13, green: 0.18, blue: 0.16)
    static let textSecondary = Color(red: 0.35, green: 0.40, blue: 0.37)
    static let accentPrimary = Color(red: 0.16, green: 0.47, blue: 0.33)
=======
    static let backgroundPrimary = Color(.systemGroupedBackground)
    // History-compare adaptive colors (dark mode ready)
    static let surfacePrimary = Color(.secondarySystemGroupedBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let accentPrimary = Color.primary
>>>>>>> a10bb3936580a6da0237730f7d536607f842fb57
    static let accentDanger = Color(red: 0.74, green: 0.20, blue: 0.20)
    static let borderSubtle = Color(.separator)

    // Homepage score severity colors
    static let scoreVeryGood = Color.green
    static let scoreGood = Color(red: 0.6, green: 0.8, blue: 0.2) // Yellow-green
    static let scoreModerate = Color.orange
    static let scoreLow = Color.red
    static let scoreVeryLow = Color(red: 0.55, green: 0.0, blue: 0.0) // Dark red
}
