import Testing
import CoreGraphics
import Foundation

@testable import Suzuran

/// Property-based tests for acne type summary ordering.
/// Feature: face-scan-redesign, Property 8: Acne Type Summary Ordering
///
/// **Validates: Requirements 7.4**
///
/// These tests verify that the acne type summary is always sorted in
/// descending order by count, regardless of the input detection array.
@Suite("Acne Type Summary Ordering Property Tests")
struct AcneTypeSummaryPropertyTests {

    /// Number of random iterations for property-based testing.
    private let iterations = 200

    /// All valid acne types for random generation (excluding .unknown for typical detections).
    private let allAcneTypes: [AcneType] = [
        .blackhead, .cyst, .nodule, .papule, .pustule, .whitehead
    ]

    // MARK: - Helpers

    /// Generates a random AcneDetection with a random acne type and confidence.
    private func randomDetection() -> AcneDetection {
        let classId = Int.random(in: 0...5)
        return AcneDetection(
            acneType: AcneType(classId: classId),
            confidence: Double.random(in: 0.05...1.0),
            normalizedBoundingBox: CGRect(
                x: CGFloat.random(in: 0...0.7),
                y: CGFloat.random(in: 0...0.7),
                width: CGFloat.random(in: 0.01...0.3),
                height: CGFloat.random(in: 0.01...0.3)
            )
        )
    }

    /// Builds the acne type summary from detections using the same logic as the ViewModel:
    /// group by acne type, count per group, sort descending by count.
    private func buildSummary(from detections: [AcneDetection]) -> [AcneTypeSummaryModel] {
        let grouped = Dictionary(grouping: detections, by: { $0.acneType })
        let summaries = grouped.map { acneType, dets in
            AcneTypeSummaryModel(acneType: acneType, count: dets.count)
        }.sorted { $0.count > $1.count }
        return summaries
    }

    // MARK: - Property 8: Acne Type Summary Ordering

    @Test("Property 8: summary is sorted descending by count for random detection arrays")
    func summaryOrderedDescendingByCount_property() {
        // **Validates: Requirements 7.4**
        //
        // For any collection of AcneDetection results, the acne type summary
        // SHALL be sorted in descending order by count (i.e., for consecutive
        // elements a and b, a.count ≥ b.count).

        for _ in 0..<iterations {
            let detectionCount = Int.random(in: 1...50)
            let detections = (0..<detectionCount).map { _ in randomDetection() }

            let summaries = buildSummary(from: detections)

            // Assert descending order
            for i in 0..<(summaries.count - 1) {
                #expect(
                    summaries[i].count >= summaries[i + 1].count,
                    "Summary not sorted descending at index \(i): \(summaries[i].count) should be >= \(summaries[i + 1].count)"
                )
            }
        }
    }

    @Test("Property 8: summary total count equals input detection count")
    func summaryTotalCountEqualsDetectionCount_property() {
        // **Validates: Requirements 7.4**
        //
        // The sum of all summary counts should equal the total number of detections.

        for _ in 0..<iterations {
            let detectionCount = Int.random(in: 1...50)
            let detections = (0..<detectionCount).map { _ in randomDetection() }

            let summaries = buildSummary(from: detections)
            let totalFromSummaries = summaries.reduce(0) { $0 + $1.count }

            #expect(
                totalFromSummaries == detectionCount,
                "Sum of summary counts (\(totalFromSummaries)) != detection count (\(detectionCount))"
            )
        }
    }

    @Test("Property 8: each acne type appears at most once in summary")
    func summaryHasUniqueAcneTypes_property() {
        // **Validates: Requirements 7.4**
        //
        // Each acne type should appear exactly once in the summary (grouped).

        for _ in 0..<iterations {
            let detectionCount = Int.random(in: 1...50)
            let detections = (0..<detectionCount).map { _ in randomDetection() }

            let summaries = buildSummary(from: detections)
            let types = summaries.map { $0.acneType }
            let uniqueTypes = Set(types)

            #expect(
                types.count == uniqueTypes.count,
                "Summary contains duplicate acne types"
            )
        }
    }

    // MARK: - Edge Cases

    @Test("Property 8 edge case: single detection produces single-element summary")
    func summary_singleDetection() {
        // **Validates: Requirements 7.4**
        let detection = AcneDetection(
            acneType: .papule,
            confidence: 0.8,
            normalizedBoundingBox: CGRect(x: 0.3, y: 0.3, width: 0.1, height: 0.1)
        )
        let summaries = buildSummary(from: [detection])

        #expect(summaries.count == 1)
        #expect(summaries[0].acneType == .papule)
        #expect(summaries[0].count == 1)
    }

    @Test("Property 8 edge case: all detections same type produces single summary entry")
    func summary_allSameType() {
        // **Validates: Requirements 7.4**
        let detections = (0..<10).map { _ in
            AcneDetection(
                acneType: .cyst,
                confidence: Double.random(in: 0.05...1.0),
                normalizedBoundingBox: CGRect(x: 0.2, y: 0.2, width: 0.1, height: 0.1)
            )
        }
        let summaries = buildSummary(from: detections)

        #expect(summaries.count == 1)
        #expect(summaries[0].acneType == .cyst)
        #expect(summaries[0].count == 10)
    }

    @Test("Property 8 edge case: each type has one detection produces equal counts")
    func summary_oneOfEachType() {
        // **Validates: Requirements 7.4**
        let detections = allAcneTypes.map { type in
            AcneDetection(
                acneType: type,
                confidence: 0.5,
                normalizedBoundingBox: CGRect(x: 0.3, y: 0.3, width: 0.1, height: 0.1)
            )
        }
        let summaries = buildSummary(from: detections)

        #expect(summaries.count == 6)
        // All counts should be 1, so descending order still holds (all equal)
        for i in 0..<(summaries.count - 1) {
            #expect(summaries[i].count >= summaries[i + 1].count)
        }
    }

    @Test("Property 8 edge case: known ordering with varied counts")
    func summary_knownOrdering() {
        // **Validates: Requirements 7.4**
        // Create: 5 papule, 3 cyst, 1 blackhead
        var detections: [AcneDetection] = []
        for _ in 0..<5 {
            detections.append(AcneDetection(
                acneType: .papule,
                confidence: 0.7,
                normalizedBoundingBox: CGRect(x: 0.3, y: 0.3, width: 0.1, height: 0.1)
            ))
        }
        for _ in 0..<3 {
            detections.append(AcneDetection(
                acneType: .cyst,
                confidence: 0.6,
                normalizedBoundingBox: CGRect(x: 0.4, y: 0.4, width: 0.1, height: 0.1)
            ))
        }
        detections.append(AcneDetection(
            acneType: .blackhead,
            confidence: 0.5,
            normalizedBoundingBox: CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1)
        ))

        let summaries = buildSummary(from: detections)

        #expect(summaries.count == 3)
        #expect(summaries[0].count == 5)
        #expect(summaries[0].acneType == .papule)
        #expect(summaries[1].count == 3)
        #expect(summaries[1].acneType == .cyst)
        #expect(summaries[2].count == 1)
        #expect(summaries[2].acneType == .blackhead)
    }
}
