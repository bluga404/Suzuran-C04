import SwiftUI

/// App color tokens. Uses adaptive system colors so elements automatically adapt to Light and Dark mode.
enum AppColor {
    static let backgroundPrimary = Color(.systemGroupedBackground)
    static let surfacePrimary = Color(.secondarySystemGroupedBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let accentPrimary = Color(red: 0.16, green: 0.47, blue: 0.33)
    static let accentDanger = Color(red: 0.74, green: 0.20, blue: 0.20)
    static let borderSubtle = Color(.separator)
}
