import Testing

@testable import Suzuran

/// Property-based tests for severity classification.
/// Feature: face-scan-redesign, Property 7: Severity Classification
///
/// **Validates: Requirements 7.6**
///
/// These tests verify that AcneSeverity(totalCount:) correctly classifies:
/// - 0 = clear
/// - 1–5 = mild
/// - 6–15 = moderate
/// - 16+ = severe
@Suite("AcneSeverity Classification Property Tests")
struct SeverityPropertyTests {

    /// Number of random iterations for property-based testing.
    private let iterations = 200

    // MARK: - Property 7: Severity Classification

    @Test("Property 7: severity classification matches thresholds for random non-negative integers")
    func severityClassification_property() {
        // **Validates: Requirements 7.6**
        //
        // For any non-negative integer total acne count, the severity classification
        // SHALL return: clear when count == 0, mild when count ∈ [1, 5],
        // moderate when count ∈ [6, 15], severe when count ≥ 16.

        for _ in 0..<iterations {
            let count = Int.random(in: 0...100)
            let severity = AcneSeverity(totalCount: count)

            let expected: AcneSeverity
            switch count {
            case 0:
                expected = .clear
            case 1...5:
                expected = .mild
            case 6...15:
                expected = .moderate
            default:
                expected = .severe
            }

            #expect(
                severity == expected,
                "Failed for count=\(count): got \(severity), expected \(expected)"
            )
        }
    }

    // MARK: - Boundary Edge Cases

    @Test("Property 7 edge case: count 0 produces .clear")
    func severity_zeroIsClear() {
        // **Validates: Requirements 7.6**
        #expect(AcneSeverity(totalCount: 0) == .clear)
    }

    @Test("Property 7 edge case: count 1 produces .mild (lower boundary)")
    func severity_oneIsMild() {
        // **Validates: Requirements 7.6**
        #expect(AcneSeverity(totalCount: 1) == .mild)
    }

    @Test("Property 7 edge case: count 5 produces .mild (upper boundary)")
    func severity_fiveIsMild() {
        // **Validates: Requirements 7.6**
        #expect(AcneSeverity(totalCount: 5) == .mild)
    }

    @Test("Property 7 edge case: count 6 produces .moderate (lower boundary)")
    func severity_sixIsModerate() {
        // **Validates: Requirements 7.6**
        #expect(AcneSeverity(totalCount: 6) == .moderate)
    }

    @Test("Property 7 edge case: count 15 produces .moderate (upper boundary)")
    func severity_fifteenIsModerate() {
        // **Validates: Requirements 7.6**
        #expect(AcneSeverity(totalCount: 15) == .moderate)
    }

    @Test("Property 7 edge case: count 16 produces .severe (lower boundary)")
    func severity_sixteenIsSevere() {
        // **Validates: Requirements 7.6**
        #expect(AcneSeverity(totalCount: 16) == .severe)
    }

    @Test("Property 7 edge case: very large count produces .severe")
    func severity_largeCountIsSevere() {
        // **Validates: Requirements 7.6**
        #expect(AcneSeverity(totalCount: 1000) == .severe)
    }
}
