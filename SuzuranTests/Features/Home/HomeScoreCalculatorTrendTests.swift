import Foundation
import Testing

@testable import Suzuran

/// Unit tests for HomeScoreCalculator.calculateTrend.
///
/// **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5**
@Suite("HomeScoreCalculator - calculateTrend")
struct HomeScoreCalculatorTrendTests {

    private let calculator = HomeScoreCalculator()

    // MARK: - Helpers

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

    // MARK: - Nil Cases (Requirements 5.4, 5.5)

    @Test("nil latest returns .noPreviousData")
    func trend_nilLatest_returnsNoPreviousData() {
        // **Validates: Requirements 5.5**
        let previous = makeScan(overallScore: 50)
        let result = calculator.calculateTrend(latest: nil, previous: previous)
        #expect(result == .noPreviousData)
    }

    @Test("nil previous returns .noPreviousData")
    func trend_nilPrevious_returnsNoPreviousData() {
        // **Validates: Requirements 5.4**
        let latest = makeScan(overallScore: 50)
        let result = calculator.calculateTrend(latest: latest, previous: nil)
        #expect(result == .noPreviousData)
    }

    @Test("both nil returns .noPreviousData")
    func trend_bothNil_returnsNoPreviousData() {
        // **Validates: Requirements 5.4, 5.5**
        let result = calculator.calculateTrend(latest: nil, previous: nil)
        #expect(result == .noPreviousData)
    }

    // MARK: - Comparison Cases (Requirements 5.1, 5.2, 5.3)

    @Test("latest score higher than previous returns .improved")
    func trend_latestHigher_returnsImproved() {
        // **Validates: Requirements 5.1**
        let latest = makeScan(overallScore: 80)
        let previous = makeScan(overallScore: 60)
        let result = calculator.calculateTrend(latest: latest, previous: previous)
        #expect(result == .improved)
    }

    @Test("latest score lower than previous returns .declined")
    func trend_latestLower_returnsDeclined() {
        // **Validates: Requirements 5.2**
        let latest = makeScan(overallScore: 40)
        let previous = makeScan(overallScore: 60)
        let result = calculator.calculateTrend(latest: latest, previous: previous)
        #expect(result == .declined)
    }

    @Test("equal scores returns .unchanged")
    func trend_equalScores_returnsUnchanged() {
        // **Validates: Requirements 5.3**
        let latest = makeScan(overallScore: 60)
        let previous = makeScan(overallScore: 60)
        let result = calculator.calculateTrend(latest: latest, previous: previous)
        #expect(result == .unchanged)
    }

    // MARK: - Boundary Values

    @Test("minimum score difference of 1 point up returns .improved")
    func trend_onePointUp_returnsImproved() {
        // **Validates: Requirements 5.1**
        let latest = makeScan(overallScore: 51)
        let previous = makeScan(overallScore: 50)
        let result = calculator.calculateTrend(latest: latest, previous: previous)
        #expect(result == .improved)
    }

    @Test("minimum score difference of 1 point down returns .declined")
    func trend_onePointDown_returnsDeclined() {
        // **Validates: Requirements 5.2**
        let latest = makeScan(overallScore: 49)
        let previous = makeScan(overallScore: 50)
        let result = calculator.calculateTrend(latest: latest, previous: previous)
        #expect(result == .declined)
    }

    @Test("both scores at 0 returns .unchanged")
    func trend_bothZero_returnsUnchanged() {
        // **Validates: Requirements 5.3**
        let latest = makeScan(overallScore: 0)
        let previous = makeScan(overallScore: 0)
        let result = calculator.calculateTrend(latest: latest, previous: previous)
        #expect(result == .unchanged)
    }

    @Test("both scores at 100 returns .unchanged")
    func trend_bothMax_returnsUnchanged() {
        // **Validates: Requirements 5.3**
        let latest = makeScan(overallScore: 100)
        let previous = makeScan(overallScore: 100)
        let result = calculator.calculateTrend(latest: latest, previous: previous)
        #expect(result == .unchanged)
    }
}
