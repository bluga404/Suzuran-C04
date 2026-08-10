import Testing

@testable import Suzuran

// Feature: home-page, Property 3: Score monotonicity
/// **Validates: Requirements 2.1, 2.2, 2.3**
@Suite("HomeScoreCalculator - Property 3: Score Monotonicity")
struct HomeScoreCalculatorMonotonicityPropertyTests {

    private let calculator = HomeScoreCalculator()

    @Test("Higher weighted count produces lower or equal score")
    func scoreMonotonicity() {
        // **Validates: Requirements 2.1, 2.2, 2.3**
        //
        // For any two weighted counts a ≤ b, score(a) ≥ score(b).
        // A higher weighted acne count means worse skin condition → lower score.
        var rng = SplitMix64(seed: 77)
        for _ in 0..<200 {
            let a = Double.random(in: 0...120, using: &rng)
            let b = Double.random(in: a...120, using: &rng) // b >= a

            let scoreA = calculator.calculateSkinHealthScore(weightedCount: a)
            let scoreB = calculator.calculateSkinHealthScore(weightedCount: b)

            #expect(
                scoreA >= scoreB,
                "Monotonicity violated: score(\(a))=\(scoreA) < score(\(b))=\(scoreB)"
            )
        }
    }
}

// MARK: - SplitMix64 Random Number Generator

/// A lightweight deterministic PRNG for reproducible property tests.
private struct SplitMix64: RandomNumberGenerator {
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
