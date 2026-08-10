import Testing

@testable import Suzuran

// Feature: home-page, Property 1: Score formula correctness
/// **Validates: Requirements 2.1, 2.2, 2.3, 2.10**
@Suite("HomeScoreCalculator - Property 1: Score Formula Correctness")
struct HomeScoreCalculatorScorePropertyTests {

    private let calculator = HomeScoreCalculator()

    @Test("Score formula produces correct result for random inputs across 200 iterations")
    func scoreFormulaCorrectness() {
        var rng = SplitMix64(seed: 42)
        let allTypes: [AcneType] = [.blackhead, .whitehead, .papule, .pustule, .nodule, .cyst, .unknown]

        for _ in 0..<200 {
            // Generate random acne counts dictionary with counts 0–50
            var counts: [AcneType: Int] = [:]
            for type in allTypes {
                counts[type] = Int.random(in: 0...50, using: &rng)
            }

            // Calculate via the system under test
            let weightedCount = calculator.calculateWeightedAcneCount(counts: counts)
            let score = calculator.calculateSkinHealthScore(weightedCount: weightedCount)

            // Independently compute expected weighted count
            let expectedWeighted = counts.reduce(0.0) { result, entry in
                result + Double(entry.value) * Double(entry.key.severityWeight)
            }
            #expect(
                weightedCount == expectedWeighted,
                "Weighted count mismatch: got \(weightedCount), expected \(expectedWeighted) for counts \(counts)"
            )

            // Verify formula: max(0, min(100, round(100 - min(weightedCount, 60) / 60 × 100)))
            let maxExpected = 60.0
            let expected = max(0, min(100, Int(round(100 - min(weightedCount, maxExpected) / maxExpected * 100))))
            #expect(
                score == expected,
                "Score mismatch: got \(score), expected \(expected) for weightedCount \(weightedCount)"
            )

            // Verify bounds: result is always in [0, 100]
            #expect(
                score >= 0 && score <= 100,
                "Score \(score) out of bounds [0, 100] for weightedCount \(weightedCount)"
            )
        }
    }

    @Test("Empty or all-zero counts always produces score 100")
    func emptyCountsProducesMaxScore() {
        // Empty dictionary
        let emptyWeighted = calculator.calculateWeightedAcneCount(counts: [:])
        let emptyScore = calculator.calculateSkinHealthScore(weightedCount: emptyWeighted)
        #expect(emptyScore == 100, "Empty dictionary should yield score 100")

        // All zeros
        let zeroCounts: [AcneType: Int] = [
            .blackhead: 0, .whitehead: 0, .papule: 0,
            .pustule: 0, .nodule: 0, .cyst: 0, .unknown: 0
        ]
        let zeroWeighted = calculator.calculateWeightedAcneCount(counts: zeroCounts)
        let zeroScore = calculator.calculateSkinHealthScore(weightedCount: zeroWeighted)
        #expect(zeroScore == 100, "All-zero counts should yield score 100")
    }

    @Test("Score is bounded [0, 100] for extreme weighted counts")
    func scoreBoundsForExtremeValues() {
        // Very high weighted count (well above maxExpected)
        let highScore = calculator.calculateSkinHealthScore(weightedCount: 1000.0)
        #expect(highScore >= 0 && highScore <= 100, "High weighted count score \(highScore) out of bounds")
        #expect(highScore == 0, "Weighted count far above 60 should yield score 0")

        // Zero weighted count
        let zeroScore = calculator.calculateSkinHealthScore(weightedCount: 0.0)
        #expect(zeroScore == 100, "Zero weighted count should yield score 100")

        // Exactly at maxExpected
        let atMaxScore = calculator.calculateSkinHealthScore(weightedCount: 60.0)
        #expect(atMaxScore == 0, "Weighted count at maxExpected (60) should yield score 0")
    }
}

// MARK: - SplitMix64 Random Number Generator

/// A simple, deterministic pseudo-random number generator for reproducible property tests.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
