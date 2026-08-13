import Testing

@testable import Suzuran

// Feature: home-page, Property 5: Dominant acne type determinism and correctness

// MARK: - SplitMix64 Random Number Generator

/// A simple, deterministic pseudo-random number generator for reproducible property tests.
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

/// **Validates: Requirements 4.1, 4.2, 4.3, 4.4**
@Suite("HomeScoreCalculator - Property 5: Dominant Acne Type")
struct HomeScoreCalculatorDominantPropertyTests {

    private let calculator = HomeScoreCalculator()
    private let priorityOrder: [AcneType] = [.blackhead, .whitehead, .papule, .pustule, .nodule, .cyst]

    @Test("Dominant type is highest count with correct tie-breaking, deterministic")
    func dominantTypeDeterminism() {
        var rng = SplitMix64(seed: 55)

        for _ in 0..<200 {
            // Generate counts with at least one > 0
            var counts: [AcneType: Int] = [:]
            for type in priorityOrder {
                counts[type] = Int.random(in: 0...30, using: &rng)
            }
            // Ensure at least one positive
            if counts.values.allSatisfy({ $0 == 0 }) {
                counts[.blackhead] = Int.random(in: 1...10, using: &rng)
            }
            // Also add unknown to verify it's excluded
            counts[.unknown] = Int.random(in: 0...50, using: &rng)

            let result = calculator.dominantAcneType(from: counts)

            // Compute expected: highest count among recognized, first in priority on tie
            let maxCount = priorityOrder.compactMap { counts[$0] }.max()!
            let expected = priorityOrder.first(where: { counts[$0] == maxCount })

            #expect(result == expected, "Expected \(String(describing: expected)) but got \(String(describing: result))")

            // Determinism: same input → same output
            let result2 = calculator.dominantAcneType(from: counts)
            #expect(result == result2)
        }
    }
}
