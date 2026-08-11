import Testing

@testable import Suzuran

// Feature: home-page, Property 7: Home state machine completeness
/// **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7**
@Suite("HomeScoreCalculator - Property 7: State Machine Completeness")
struct HomeScoreCalculatorStateMachinePropertyTests {

    private let calculator = HomeScoreCalculator()

    private let validStates: Set<HomeSummaryState> = [
        .empty, .faceOnly, .complete, .improvement, .degradation, .unchanged
    ]

    private func makeScan(overallScore: Int) -> SkinScan {
        SkinScan(
            id: UUID(),
            userID: UUID(),
            createdAt: Date(),
            overallScore: overallScore,
            weightedAcneCount: 0.0,
            gagsScore: 0,
            acneCounts: [:],
            regionCounts: [:],
            regionGagsScores: [:],
            imageReference: nil,
            modelVersion: nil,
            scanProtocolVersion: nil
        )
    }

    @Test("State machine is complete and follows precedence for random inputs")
    func stateMachineCompleteness() {
        var rng = StateMachineSplitMix64(seed: 101)

        for _ in 0..<200 {
            // Random Optional<SkinScan> × Optional<SkinScan> × Bool
            let hasLatest = Bool.random(using: &rng)
            let hasPrevious = Bool.random(using: &rng)
            let hasIngredient = Bool.random(using: &rng)

            let latestScore = Int.random(in: 0...100, using: &rng)
            let previousScore = Int.random(in: 0...100, using: &rng)

            let latestScan: SkinScan? = hasLatest ? makeScan(overallScore: latestScore) : nil
            let previousScan: SkinScan? = hasPrevious ? makeScan(overallScore: previousScore) : nil

            let result = calculator.determineHomeState(
                latestScan: latestScan,
                previousScan: previousScan,
                hasIngredientScan: hasIngredient
            )

            // Always returns a valid state (completeness — never crashes)
            #expect(
                validStates.contains(result),
                "Result \(result) is not one of the 6 valid HomeSummaryState values"
            )

            // Verify precedence rules
            if latestScan == nil {
                #expect(
                    result == .empty,
                    "nil latestScan should yield .empty, got \(result)"
                )
            } else if !hasIngredient {
                #expect(
                    result == .faceOnly,
                    "!hasIngredientScan should yield .faceOnly, got \(result)"
                )
            } else if previousScan == nil {
                #expect(
                    result == .complete,
                    "nil previousScan (with latestScan + hasIngredient) should yield .complete, got \(result)"
                )
            } else {
                if latestScore > previousScore {
                    #expect(
                        result == .improvement,
                        "latestScore(\(latestScore)) > previousScore(\(previousScore)) should yield .improvement, got \(result)"
                    )
                } else if latestScore < previousScore {
                    #expect(
                        result == .degradation,
                        "latestScore(\(latestScore)) < previousScore(\(previousScore)) should yield .degradation, got \(result)"
                    )
                } else {
                    #expect(
                        result == .unchanged,
                        "latestScore(\(latestScore)) == previousScore(\(previousScore)) should yield .unchanged, got \(result)"
                    )
                }
            }
        }
    }
}

// MARK: - Private SplitMix64 RNG (avoids conflicts with other test files)

/// A simple, deterministic pseudo-random number generator for reproducible property tests.
private struct StateMachineSplitMix64: RandomNumberGenerator {
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
