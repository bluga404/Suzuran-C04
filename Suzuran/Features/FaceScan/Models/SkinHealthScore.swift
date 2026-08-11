import SwiftUI

// MARK: - Skin Health Result

struct SkinHealthResult: Sendable, Equatable {
    let score: Int
    let weightedCount: Float
    let label: String
    
    // UI elements like Color shouldn't strictly be in the model if we use pure MVVM,
    // but we can map it to a hex string or standard color in the view.
    // For simplicity with previous branch compatibility, we'll keep it.
    let color: Color
    
    // AcneType is Hashable because it's String raw value.
    let breakdown: [AcneType: Int]
}

// MARK: - Skin Health Score Calculator

/// Implements the scoring formula from PRD §2.2.4
/// Uses HomeScoreCalculator as the single source of truth for score computation.
enum SkinHealthScore {
    /// MaxExpected calibration value from PRD
    private nonisolated static let maxExpected: Double = 60.0

    nonisolated static func calculate(from detections: [AcneDetection]) -> SkinHealthResult {
        // Count per type
        var breakdown: [AcneType: Int] = [:]
        for type in AcneType.allCases {
            breakdown[type] = 0
        }
        for detection in detections {
            breakdown[detection.acneType, default: 0] += 1
        }

        // Use HomeScoreCalculator for consistent scoring (Double precision)
        let calculator = HomeScoreCalculator()
        let weightedCount = calculator.calculateWeightedAcneCount(counts: breakdown)
        let skinHealthScore = calculator.calculateSkinHealthScore(weightedCount: weightedCount)
        let label = calculator.scoreLabel(for: skinHealthScore)
        let color = scoreColor(for: skinHealthScore)

        return SkinHealthResult(
            score: skinHealthScore,
            weightedCount: Float(weightedCount),
            label: label,
            color: color,
            breakdown: breakdown
        )
    }

    /// Score colors matching the updated 5-tier severity labels.
    private nonisolated static func scoreColor(for score: Int) -> Color {
        switch score {
        case 100: return .green
        case 55...99: return Color(red: 0.6, green: 0.8, blue: 0.2)
        case 25...54: return .orange
        case 5...24: return .red
        default: return Color(red: 0.55, green: 0.0, blue: 0.0)
        }
    }
}
