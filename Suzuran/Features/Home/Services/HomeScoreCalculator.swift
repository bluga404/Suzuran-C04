import Foundation

/// Pure computation service for skin health scoring.
/// Contains weighted acne count calculation, skin health score derivation,
/// GAGS calculation, dominant acne type determination, trend calculation,
/// and home state machine logic for the Home feature.
struct HomeScoreCalculator {

    /// Normalization constant: weighted counts at or above this value map to score 0.
    static let maxExpected: Double = 60.0

    // MARK: - Weighted Acne Count

    /// Computes the weighted acne count by summing (count × severityWeight) for each type.
    /// - Parameter counts: Dictionary mapping each `AcneType` to its detection count.
    /// - Returns: The weighted sum as a `Double`.
    func calculateWeightedAcneCount(counts: [AcneType: Int]) -> Double {
        counts.reduce(0.0) { result, entry in
            result + Double(entry.value) * Double(entry.key.severityWeight)
        }
    }

    // MARK: - Skin Health Score

    /// Converts a weighted acne count into a 0–100 skin health score (higher is better).
    /// - Parameter weightedCount: The weighted acne count (≥ 0).
    /// - Returns: An integer score clamped to [0, 100].
    func calculateSkinHealthScore(weightedCount: Double) -> Int {
        max(0, min(100, Int(round(100 - min(weightedCount, Self.maxExpected) / Self.maxExpected * 100))))
    }

    // MARK: - Score Label

    /// Returns the 5-tier label for a given skin health score.
    /// - Parameter score: An integer score in [0, 100].
    /// - Returns: One of "Very Good", "Good", "Moderate", "Low", or "Very Low".
    func scoreLabel(for score: Int) -> String {
        switch score {
        case 100: return "Very Good"
        case 55...99: return "Good"
        case 25...54: return "Moderate"
        case 5...24: return "Low"
        default: return "Very Low" // 0-4
        }
    }

    // MARK: - GAGS Calculation

    /// Maps an `AcneType` to its GAGS lesion severity value.
    /// - Parameter type: The acne type to map.
    /// - Returns: GAGS severity (0–4).
    private func gagsSeverity(for type: AcneType) -> Double {
        switch type {
        case .blackhead, .whitehead: return 0.5
        case .papule: return 1.0
        case .pustule: return 2.0
        case .nodule, .cyst: return 3.0
        case .unknown: return 0.0
        }
    }

    /// Computes GAGS (Global Acne Grading System) scores per zone and total.
    /// Each zone score = gagsFactor × highest lesion severity present in that zone.
    /// - Parameter regionCounts: Per-region breakdown of acne type counts.
    /// - Returns: A tuple of per-zone scores and total GAGS score.
    func calculateGAGS(regionCounts: [FaceRegion: [AcneType: Int]]) -> (zoneScores: [FaceRegion: Int], total: Int) {
        var zoneScores: [FaceRegion: Int] = [:]
        for region in FaceRegion.allCases {
            let counts = regionCounts[region] ?? [:]
            let highestSeverity = counts
                .filter { $0.value > 0 }
                .map { gagsSeverity(for: $0.key) }
                .max() ?? 0.0
            zoneScores[region] = Int(round(Double(region.gagsFactor) * highestSeverity))
        }
        let total = zoneScores.values.reduce(0, +)
        return (zoneScores: zoneScores, total: total)
    }

    // MARK: - Dominant Acne Type

    /// Priority order for tie-breaking when multiple types have the same highest count.
    private static let priorityOrder: [AcneType] = [
        .blackhead, .whitehead, .papule, .pustule, .nodule, .cyst
    ]

    /// Determines the dominant acne type from a counts dictionary.
    /// - Parameter counts: Dictionary mapping each `AcneType` to its detection count.
    /// - Returns: The type with the highest count among the 6 recognized types (excludes `.unknown`).
    ///   Returns `nil` if all recognized counts are zero or absent.
    ///   Tie-breaks by priority order: blackhead > whitehead > papule > pustule > nodule > cyst.
    func dominantAcneType(from counts: [AcneType: Int]) -> AcneType? {
        let recognizedCounts = Self.priorityOrder.compactMap { type -> (AcneType, Int)? in
            guard let count = counts[type], count > 0 else { return nil }
            return (type, count)
        }
        guard !recognizedCounts.isEmpty else { return nil }
        let maxCount = recognizedCounts.map(\.1).max()!
        return recognizedCounts.first(where: { $0.1 == maxCount })?.0
    }

    // MARK: - Score Trend

    /// Calculates the trend direction between two scans based on their overall scores.
    /// - Parameters:
    ///   - latest: The most recent scan (nil if no scan exists).
    ///   - previous: The previous scan (nil if no prior scan exists).
    /// - Returns: The `ScoreTrend` indicating improvement, decline, unchanged, or no data.
    func calculateTrend(latest: SkinScan?, previous: SkinScan?) -> ScoreTrend {
        guard let latest = latest, let previous = previous else {
            return .noPreviousData
        }
        if latest.overallScore > previous.overallScore {
            return .improved
        } else if latest.overallScore < previous.overallScore {
            return .declined
        } else {
            return .unchanged
        }
    }

    // MARK: - Home State Machine

    /// Determines the home summary state based on scan availability and score comparison.
    /// Precedence: nil latestScan → .empty, !hasIngredientScan → .faceOnly,
    /// nil previousScan → .complete, then score comparison.
    /// - Parameters:
    ///   - latestScan: The most recent face scan (nil if none exists).
    ///   - previousScan: The previous face scan (nil if none exists).
    ///   - hasIngredientScan: Whether an ingredient scan has been completed.
    /// - Returns: The appropriate `HomeSummaryState`.
    func determineHomeState(latestScan: SkinScan?, previousScan: SkinScan?, hasIngredientScan: Bool) -> HomeSummaryState {
        guard let latestScan = latestScan else { return .empty }
        guard hasIngredientScan else { return .faceOnly }
        guard let previousScan = previousScan else { return .complete }
        if latestScan.overallScore > previousScan.overallScore {
            return .improvement
        } else if latestScan.overallScore < previousScan.overallScore {
            return .degradation
        } else {
            return .unchanged
        }
    }
}
