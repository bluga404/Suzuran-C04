import SwiftUI

// MARK: - Skin Health Result

struct SkinHealthResult: Sendable {
    let score: Int
    let weightedCount: Float
    let label: String
    let color: Color
    let breakdown: [AcneType: Int]
}

// MARK: - Skin Health Score Calculator

/// Implements the scoring formula from PRD §2.2.4
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

        // Step 1: Weighted Acne Count
        var weightedCount: Float = 0.0
        for (type, count) in breakdown {
            weightedCount += Float(count) * type.severityWeight
        }

        // Step 2: Normalize
        //   raw_score = min(weighted_count, MaxExpected) / MaxExpected × 100
        let rawScore = min(Double(weightedCount), maxExpected) / maxExpected * 100.0

        // Step 3: Invert to "health" perspective
        //   skin_health_score = 100 - raw_score
        let skinHealthScore = max(0, min(100, Int(round(100.0 - rawScore))))

        let (label, color) = severityLabel(for: skinHealthScore)

        return SkinHealthResult(
            score: skinHealthScore,
            weightedCount: weightedCount,
            label: label,
            color: color,
            breakdown: breakdown
        )
    }

    /// Severity labels from PRD §2.2.4
    private nonisolated static func severityLabel(for score: Int) -> (String, Color) {
        switch score {
        case 85...100:
            return ("Excellent", .green)
        case 70...84:
            return ("Good", Color(red: 0.6, green: 0.8, blue: 0.2))
        case 50...69:
            return ("Moderate", .orange)
        case 25...49:
            return ("Needs Attention", .red)
        default:
            return ("Severe", Color(red: 0.55, green: 0.0, blue: 0.0))
        }
    }
}
