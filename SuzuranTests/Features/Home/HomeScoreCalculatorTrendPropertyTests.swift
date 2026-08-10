import Testing

@testable import Suzuran

// Feature: home-page, Property 6: Trend calculation symmetry and correctness
/// **Validates: Requirements 5.1, 5.2, 5.3**
@Suite("HomeScoreCalculator - Property 6: Trend Symmetry")
struct HomeScoreCalculatorTrendPropertyTests {

    private let calculator = HomeScoreCalculator()

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

    @Test("Trend symmetry: improved ↔ declined, equal → unchanged")
    func trendSymmetry() {
        var rng = SplitMix64(seed: 88)
        for _ in 0..<200 {
            let scoreA = Int.random(in: 0...100, using: &rng)
            let scoreB = Int.random(in: 0...100, using: &rng)
            let scanA = makeScan(overallScore: scoreA)
            let scanB = makeScan(overallScore: scoreB)

            let trendAB = calculator.calculateTrend(latest: scanA, previous: scanB)
            let trendBA = calculator.calculateTrend(latest: scanB, previous: scanA)

            if scoreA == scoreB {
                #expect(trendAB == .unchanged,
                    "Equal scores (\(scoreA)) should yield .unchanged, got \(trendAB)")
                #expect(trendBA == .unchanged,
                    "Equal scores (\(scoreA)) should yield .unchanged, got \(trendBA)")
            } else if trendAB == .improved {
                #expect(trendBA == .declined,
                    "Symmetry: if A(\(scoreA))>B(\(scoreB)) is improved, B>A should be declined")
            } else if trendAB == .declined {
                #expect(trendBA == .improved,
                    "Symmetry: if A(\(scoreA))<B(\(scoreB)) is declined, B>A should be improved")
            }
        }
    }
}
