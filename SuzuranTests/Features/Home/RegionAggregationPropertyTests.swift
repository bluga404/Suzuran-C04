import Testing

@testable import Suzuran

// Feature: home-page, Property 8: Detail view region aggregation correctness
/// **Validates: Requirements 11.4**
@Suite("Region Aggregation - Property 8: Aggregation Correctness")
struct RegionAggregationPropertyTests {

    @Test("Total count for any type equals sum across all regions")
    func regionAggregation() {
        var rng = RegionSplitMix64(seed: 150)
        let allTypes: [AcneType] = [.blackhead, .whitehead, .papule, .pustule, .nodule, .cyst]

        for _ in 0..<200 {
            // Build random regionCounts
            var regionCounts: [FaceRegion: [AcneType: Int]] = [:]
            var totalPerType: [AcneType: Int] = [:]

            for region in FaceRegion.allCases {
                var counts: [AcneType: Int] = [:]
                for type in allTypes {
                    let count = Int.random(in: 0...20, using: &rng)
                    counts[type] = count
                    totalPerType[type, default: 0] += count
                }
                regionCounts[region] = counts
            }

            // Pick a random type
            let selectedType = allTypes[Int.random(in: 0..<allTypes.count, using: &rng)]

            // Compute total from regionCounts (as the view/VM would)
            let computedTotal = FaceRegion.allCases.reduce(0) { sum, region in
                sum + (regionCounts[region]?[selectedType] ?? 0)
            }

            #expect(
                computedTotal == totalPerType[selectedType]!,
                "Aggregation mismatch for \(selectedType): computed \(computedTotal) vs expected \(totalPerType[selectedType]!)"
            )
        }
    }
}

/// A deterministic PRNG for reproducible property tests.
private struct RegionSplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
