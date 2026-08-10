import Testing

@testable import Suzuran

// Feature: home-page, Property 4: GAGS calculation correctness and bounds
/// **Validates: Requirements 3.1, 3.2, 3.3**
@Suite("HomeScoreCalculator - Property 4: GAGS Correctness")
struct HomeScoreCalculatorGAGSPropertyTests {

    private let calculator = HomeScoreCalculator()

    /// Maps AcneType to GAGS lesion severity for independent verification.
    private func gagsSeverity(for type: AcneType) -> Int {
        switch type {
        case .blackhead, .whitehead: return 1
        case .papule: return 2
        case .pustule: return 3
        case .nodule, .cyst: return 4
        case .unknown: return 0
        }
    }

    @Test("GAGS total equals sum of gagsFactor × highest severity per zone, bounded [0, 44]")
    func gagsCorrectnessAndBounds() {
        var rng = SplitMix64(seed: 99)
        let allTypes: [AcneType] = [.blackhead, .whitehead, .papule, .pustule, .nodule, .cyst, .unknown]

        for _ in 0..<200 {
            var regionCounts: [FaceRegion: [AcneType: Int]] = [:]
            for region in FaceRegion.allCases {
                var counts: [AcneType: Int] = [:]
                for type in allTypes {
                    counts[type] = Int.random(in: 0...20, using: &rng)
                }
                regionCounts[region] = counts
            }

            let result = calculator.calculateGAGS(regionCounts: regionCounts)

            // Verify formula independently per zone
            var expectedTotal = 0
            for region in FaceRegion.allCases {
                let counts = regionCounts[region] ?? [:]
                let highestSev = counts
                    .filter { $0.value > 0 }
                    .map { gagsSeverity(for: $0.key) }
                    .max() ?? 0
                let expectedZone = region.gagsFactor * highestSev
                #expect(
                    result.zoneScores[region] == expectedZone,
                    "Zone \(region) score mismatch: got \(result.zoneScores[region] ?? -1), expected \(expectedZone)"
                )
                expectedTotal += expectedZone
            }

            // Total equals sum of zone scores
            #expect(
                result.total == expectedTotal,
                "Total mismatch: got \(result.total), expected \(expectedTotal)"
            )

            // Total bounded [0, 44]
            #expect(
                result.total >= 0 && result.total <= 44,
                "Total \(result.total) out of bounds [0, 44]"
            )
        }
    }
}
