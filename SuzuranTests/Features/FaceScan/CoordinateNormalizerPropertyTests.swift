import Testing
import CoreGraphics

@testable import Suzuran

/// Property-based tests for coordinate normalization without Y-flip.
/// Feature: face-scan-redesign, Property 5: Coordinate Normalization Without Y-Flip
///
/// **Validates: Requirements 6.1, 6.2, 6.3**
///
/// These tests verify that CoordinateNormalizer.normalize correctly:
/// - Converts YOLO pixel coordinates (0–640) to normalized midpoint (0–1)
/// - Computes midX = ((x1+x2)/2)/640, midY = ((y1+y2)/2)/640
/// - Does NOT apply a Y-axis flip (no `1-y` transformation)
/// - Clamps results to [0, 1]
@Suite("CoordinateNormalizer Property Tests")
struct CoordinateNormalizerPropertyTests {

    /// Number of random iterations for property-based testing.
    private let iterations = 200

    /// Acceptable floating-point tolerance for comparisons.
    private let epsilon: CGFloat = 0.0001

    // MARK: - Property 5: Coordinate Normalization Without Y-Flip

    @Test("Property 5: normalize produces correct midpoint without Y-flip for random coordinates")
    func normalizationNoYFlip_property() {
        // **Validates: Requirements 6.1, 6.2, 6.3**
        //
        // For any (x1, y1, x2, y2) in [0, 640], CoordinateNormalizer.normalize SHALL:
        //   - Return midX = ((x1+x2)/2)/640
        //   - Return midY = ((y1+y2)/2)/640 (NO Y-flip)
        //   - Clamp both values to [0, 1]

        for _ in 0..<iterations {
            let x1 = CGFloat.random(in: 0...640)
            let y1 = CGFloat.random(in: 0...640)
            let x2 = CGFloat.random(in: 0...640)
            let y2 = CGFloat.random(in: 0...640)

            let result = CoordinateNormalizer.normalize(x1: x1, y1: y1, x2: x2, y2: y2)

            // Expected midpoint (without Y-flip)
            let expectedMidX = ((x1 + x2) / 2.0) / 640.0
            let expectedMidY = ((y1 + y2) / 2.0) / 640.0

            // Clamp expected to [0, 1]
            let clampedExpectedX = min(max(expectedMidX, 0), 1)
            let clampedExpectedY = min(max(expectedMidY, 0), 1)

            // Verify X coordinate matches expected midpoint
            #expect(
                abs(result.x - clampedExpectedX) < epsilon,
                "X mismatch: got \(result.x), expected \(clampedExpectedX) for x1=\(x1), x2=\(x2)"
            )

            // Verify Y coordinate matches expected midpoint (NO Y-flip)
            #expect(
                abs(result.y - clampedExpectedY) < epsilon,
                "Y mismatch: got \(result.y), expected \(clampedExpectedY) for y1=\(y1), y2=\(y2)"
            )

            // Verify results are in [0, 1]
            #expect(result.x >= 0, "result.x must be >= 0, got \(result.x)")
            #expect(result.x <= 1, "result.x must be <= 1, got \(result.x)")
            #expect(result.y >= 0, "result.y must be >= 0, got \(result.y)")
            #expect(result.y <= 1, "result.y must be <= 1, got \(result.y)")
        }
    }

    // MARK: - Property 5: No Y-Flip Verification

    @Test("Property 5: Y coordinate is NOT flipped (y != 1 - midY for non-center values)")
    func normalizationNoYFlip_verifyNoFlip() {
        // **Validates: Requirements 6.3**
        //
        // For coordinates where the midpoint Y is NOT 0.5 (center),
        // the result.y must differ from `1 - expectedMidY`, proving no Y-flip.

        for _ in 0..<iterations {
            // Generate coordinates where midY is away from 0.5
            // to ensure Y-flip would produce a detectably different value
            let y1 = CGFloat.random(in: 0...200)
            let y2 = CGFloat.random(in: 0...200)
            let x1 = CGFloat.random(in: 0...640)
            let x2 = CGFloat.random(in: 0...640)

            let result = CoordinateNormalizer.normalize(x1: x1, y1: y1, x2: x2, y2: y2)

            let expectedMidY = ((y1 + y2) / 2.0) / 640.0
            let clampedExpectedY = min(max(expectedMidY, 0), 1)
            let flippedY = 1.0 - clampedExpectedY

            // If clampedExpectedY != 0.5, then result.y should NOT equal flippedY
            if abs(clampedExpectedY - 0.5) > epsilon {
                #expect(
                    abs(result.y - flippedY) > epsilon,
                    "Y appears to be flipped: result.y=\(result.y), flippedY=\(flippedY), expectedY=\(clampedExpectedY)"
                )
            }

            // And it SHOULD equal the non-flipped value
            #expect(
                abs(result.y - clampedExpectedY) < epsilon,
                "Y should match non-flipped midY: got \(result.y), expected \(clampedExpectedY)"
            )
        }
    }

    // MARK: - Property 5: Edge Cases

    @Test("Property 5 edge case: coordinates at origin (0,0,0,0) produce midpoint (0,0)")
    func normalization_origin() {
        // **Validates: Requirements 6.1, 6.2**
        let result = CoordinateNormalizer.normalize(x1: 0, y1: 0, x2: 0, y2: 0)
        #expect(abs(result.x - 0.0) < epsilon)
        #expect(abs(result.y - 0.0) < epsilon)
    }

    @Test("Property 5 edge case: coordinates at max (640,640,640,640) produce midpoint (1,1)")
    func normalization_maxBounds() {
        // **Validates: Requirements 6.1, 6.2**
        let result = CoordinateNormalizer.normalize(x1: 640, y1: 640, x2: 640, y2: 640)
        #expect(abs(result.x - 1.0) < epsilon)
        #expect(abs(result.y - 1.0) < epsilon)
    }

    @Test("Property 5 edge case: full-image box (0,0,640,640) produces center (0.5, 0.5)")
    func normalization_fullImage() {
        // **Validates: Requirements 6.1, 6.2**
        let result = CoordinateNormalizer.normalize(x1: 0, y1: 0, x2: 640, y2: 640)
        #expect(abs(result.x - 0.5) < epsilon)
        #expect(abs(result.y - 0.5) < epsilon)
    }

    @Test("Property 5 edge case: asymmetric box verifies no Y-flip")
    func normalization_asymmetricBox() {
        // **Validates: Requirements 6.1, 6.2, 6.3**
        // Box in upper-left quadrant: midY should be < 0.5, not > 0.5
        let result = CoordinateNormalizer.normalize(x1: 0, y1: 0, x2: 320, y2: 128)
        // midX = 160/640 = 0.25, midY = 64/640 = 0.1
        #expect(abs(result.x - 0.25) < epsilon)
        #expect(abs(result.y - 0.1) < epsilon)

        // If Y-flip were applied, result.y would be 1.0 - 0.1 = 0.9
        #expect(abs(result.y - 0.9) > epsilon, "Y should NOT be flipped to 0.9")
    }

    @Test("Property 5 edge case: box in bottom-right verifies no Y-flip")
    func normalization_bottomRight() {
        // **Validates: Requirements 6.1, 6.2, 6.3**
        // Box in lower-right quadrant: midY should be > 0.5
        let result = CoordinateNormalizer.normalize(x1: 320, y1: 480, x2: 640, y2: 640)
        // midX = 480/640 = 0.75, midY = 560/640 = 0.875
        #expect(abs(result.x - 0.75) < epsilon)
        #expect(abs(result.y - 0.875) < epsilon)

        // If Y-flip were applied, result.y would be 1.0 - 0.875 = 0.125
        #expect(abs(result.y - 0.125) > epsilon, "Y should NOT be flipped to 0.125")
    }
}
