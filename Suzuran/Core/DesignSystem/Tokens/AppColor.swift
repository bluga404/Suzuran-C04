import SwiftUI

/// App color tokens. Uses adaptive system colors so elements automatically adapt to Light and Dark mode.
enum AppColor {
    static let backgroundPrimary = Color(.systemGroupedBackground)
    // History-compare adaptive colors (dark mode ready)
    static let surfacePrimary = Color(.secondarySystemGroupedBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textOnAccent = Color(UIColor.systemBackground) // Inverted color for text on accent background
    static let accentPrimary = Color(lightHex: 0x5B4EB1, darkHex: 0x7668D6)
    static let accentDanger = Color(red: 0.74, green: 0.20, blue: 0.20)
    static let borderSubtle = Color(.separator)

    // Skin Condition Score Colors (Fixed Hex)
    static let scoreVeryGood = Color(lightHex: 0xE8E5F9, darkHex: 0xE8E5F9)
    static let scoreGood     = Color(lightHex: 0xD6D0FF, darkHex: 0xD6D0FF)
    static let scoreModerate = Color(lightHex: 0xBDB4FA, darkHex: 0xBDB4FA)
    static let scoreLow      = Color(lightHex: 0x8172E5, darkHex: 0x8172E5)
    static let scoreVeryLow  = Color(lightHex: 0x5649AC, darkHex: 0x5649AC)
    
    // Ingredient recommendation colors (Adaptive)
    static let accentPurple = Color(lightHex: 0x5B4EB1, darkHex: 0x9388E4)
    static let accentPurpleBackground = Color(lightHex: 0xF3F0FC, darkHex: 0x251F41)
    
    // Acne Type Colors (Fixed Hex)
    static let acneWhitehead = Color(lightHex: 0x5AB14F, darkHex: 0x5AB14F)
    static let acneBlackhead = Color(lightHex: 0xA5B14E, darkHex: 0xA5B14E)
    static let acnePapule    = Color(lightHex: 0x4E8CB2, darkHex: 0x4E8CB2)
    static let acnePustule   = Color(lightHex: 0xA54EB1, darkHex: 0xA54EB1)
    static let acneNodule    = Color(lightHex: 0xB14E73, darkHex: 0xB14E73)
    static let acneCyst      = Color(lightHex: 0xB1744F, darkHex: 0xB1744F)
    
    // Custom exact brand colors (Adaptive)
    static let surfacePurple = Color(lightHex: 0xDDD9F8, darkHex: 0x362D5A)
    static let buttonPrimaryPurple = Color(lightHex: 0x5B4EB1, darkHex: 0x7668D6)
    
    // Tips insight background token (Adaptive D4D4D4 28% opacity)
    static let surfaceTipsBackground = Color(UIColor { traitCollection in
        let isDark = traitCollection.userInterfaceStyle == .dark
        let hex: UInt32 = isDark ? 0x3A3A3C : 0xD4D4D4
        let alpha: CGFloat = isDark ? 0.40 : 0.28
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    })
}

extension Color {
    init(lightHex: UInt32, darkHex: UInt32) {
        self.init(UIColor { traitCollection in
            let hex = traitCollection.userInterfaceStyle == .dark ? darkHex : lightHex
            let r = CGFloat((hex >> 16) & 0xFF) / 255.0
            let g = CGFloat((hex >> 8) & 0xFF) / 255.0
            let b = CGFloat(hex & 0xFF) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        })
    }
}
