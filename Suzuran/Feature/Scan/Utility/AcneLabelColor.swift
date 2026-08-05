import SwiftUI

/// Maps acne classification labels to their corresponding display colors.
enum AcneLabelColor {
    /// Returns the color associated with a given acne label.
    /// - Parameter label: The acne classification label (case-insensitive).
    /// - Returns: A SwiftUI `Color` corresponding to the label.
    static func color(for label: String) -> Color {
        switch label.lowercased() {
        case "comedo":
            return .yellow
        case "papule":
            return .orange
        case "pustule":
            return .red
        case "nodule/cystic":
            return .purple
        default:
            return .gray
        }
    }
}
