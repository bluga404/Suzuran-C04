import Testing

@testable import Suzuran

// Feature: home-page, Property 2: Score label mapping totality


/// **Validates: Requirements 2.4, 2.5, 2.6, 2.7, 2.8**
@Suite("HomeScoreCalculator - Property 2: Label Totality")
struct HomeScoreCalculatorLabelPropertyTests {
    private let calculator = HomeScoreCalculator()
    private let validLabels: Set<String> = ["Very Good", "Good", "Moderate", "Low", "Very Low"]

    @Test("Score label is total and correct for all valid scores")
    func scoreLabelTotality() {
        // Test all 101 possible values (exhaustive for this small domain)
        for score in 0...100 {
            let label = calculator.scoreLabel(for: score)

            // Exactly one valid label
            #expect(validLabels.contains(label), "Invalid label '\(label)' for score \(score)")

            // Correct boundary mapping
            let expectedLabel: String
            switch score {
            case 100: expectedLabel = "Very Good"
            case 55...99: expectedLabel = "Good"
            case 25...54: expectedLabel = "Moderate"
            case 5...24: expectedLabel = "Low"
            default: expectedLabel = "Very Low"
            }
            #expect(label == expectedLabel, "Expected '\(expectedLabel)' for score \(score), got '\(label)'")
        }
    }

    @Test("Score label returns valid label for random inputs in [0, 100]")
    func scoreLabelRandomInputs() {
        var rng = SplitMix64(seed: 123)
        for _ in 0..<200 {
            let score = Int.random(in: 0...100, using: &rng)
            let label = calculator.scoreLabel(for: score)
            #expect(validLabels.contains(label))
        }
    }
}
