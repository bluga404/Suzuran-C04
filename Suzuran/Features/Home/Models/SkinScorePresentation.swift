import Foundation

/// Presentation model for the skin health score displayed on the Home screen.
/// Contains the numeric score, its human-readable label, trend direction, and a contextual message.
struct SkinScorePresentation: Equatable {
    /// Skin health score value, range 0-100
    let value: Int
    /// Human-readable label: "Very Good", "Good", "Moderate", "Low", or "Very Low"
    let title: String
    /// Score direction relative to previous scan
    let trend: ScoreTrend
    /// Contextual message for the user, maximum 120 characters
    let message: String
}
