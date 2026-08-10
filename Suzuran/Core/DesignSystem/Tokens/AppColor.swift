import SwiftUI

enum AppColor {
    static let backgroundPrimary = Color(.systemGroupedBackground)
    static let surfacePrimary = Color.white
    static let textPrimary = Color(red: 0.13, green: 0.18, blue: 0.16)
    static let textSecondary = Color(red: 0.35, green: 0.40, blue: 0.37)
    static let accentPrimary = Color(red: 0.16, green: 0.47, blue: 0.33)
    static let accentDanger = Color(red: 0.74, green: 0.20, blue: 0.20)
    static let borderSubtle = Color(red: 0.84, green: 0.87, blue: 0.85)

    // Score severity colors
    static let scoreVeryGood = Color.green
    static let scoreGood = Color(red: 0.6, green: 0.8, blue: 0.2) // Yellow-green
    static let scoreModerate = Color.orange
    static let scoreLow = Color.red
    static let scoreVeryLow = Color(red: 0.55, green: 0.0, blue: 0.0) // Dark red
}
