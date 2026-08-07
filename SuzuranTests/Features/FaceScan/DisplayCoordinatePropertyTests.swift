import Testing
import CoreGraphics

@testable import Suzuran

/// Property-based tests for display coordinate clamping and scaling.
/// Feature: face-scan-redesign, Property 6: Display Coordinate Clamping and Scaling
///
/// **Validates: Requirements 6.4, 6.5**
///
/// These tests verify that CoordinateNormalizer.displayPosition correctly:
/// - Clamps normalized input coordinates to [0, 1] before scaling
/// - Scales clamped coordinates by the display dimensions
/// - Produces results within [0, width] for x and [0, height] for y
@Suite("CoordinateNormalizer Display Coordinate Property Tests")
struct DisplayCoordinatePropertyTests {

    /// Number of random iterations for property-based testing.
    private let iterations = 200

    /// Acceptable floating-point tolerance for comparisons.
    private let accuracy: CGFloat = 0.001

    // MARK: - Property 6: Display Coordinate Clamping and Scaling

    @Test("Property 6: displayPosition = clamp(normalized, 0, 1) × dimension for random inputs including out-of-bounds")
    func displayPositionClampingAndScaling_property() {
        // **Validates: Requirements 6.4, 6.5**
        //
        // For any normalized coordinate (possibly outside [0, 1]) and any positive
        // display dimensions, the display position SHALL equal clamp(normalized, 0, 1) × dimension,
        // producing a result within [0, width] for x and [0, height] for y.

        for _ in 0..<iterations {
            // Generate normalized points that may be out of bounds
            let normX = CGFloat.random(in: -0.5...1.5)
            let normY = CGFloat.random(in: -0.5...1.5)
            let point = CGPoint(x: normX, y: normY)

            // Generate positive display dimensions
            let displayWidth = CGFloat.random(in: 100...1000)
            let displayHeight = CGFloat.random(in: 100...1000)

            let result = CoordinateNormalizer.displayPosition(
                normalizedPoint: point,
                displayWidth: displayWidth,
                displayHeight: displayHeight
            )

            // Expected: clamp to [0, 1] then scale
            let expectedX = min(max(normX, 0), 1) * displayWidth
            let expectedY = min(max(normY, 0), 1) * displayHeight

            #expect(
                abs(result.x - expectedX) < accuracy,
                "X failed for normX=\(normX), width=\(displayWidth): got \(result.x), expected \(expectedX)"
            )
            #expect(
                abs(result.y - expectedY) < accuracy,
                "Y failed for normY=\(normY), height=\(displayHeight): got \(result.y), expected \(expectedY)"
            )

            // Verify result is within valid display bounds
            #expect(
                result.x >= 0,
                "result.x should be >= 0, got \(result.x)"
            )
            #expect(
                result.x <= displayWidth,
                "result.x should be <= displayWidth (\(displayWidth)), got \(result.x)"
            )
            #expect(
                result.y >= 0,
                "result.y should be >= 0, got \(result.y)"
            )
            #expect(
                result.y <= displayHeight,
                "result.y should be <= displayHeight (\(displayHeight)), got \(result.y)"
            )
        }
    }

    // MARK: - Edge Cases

    @Test("Property 6 edge case: negative normalized coordinates are clamped to zero")
    func displayPosition_negativeInputsClamped() {
        // **Validates: Requirements 6.4, 6.5**
        let point = CGPoint(x: -0.5, y: -1.0)
        let result = CoordinateNormalizer.displayPosition(
            normalizedPoint: point,
            displayWidth: 400,
            displayHeight: 600
        )

        #expect(abs(result.x - 0) < accuracy, "Negative x should clamp to 0, got \(result.x)")
        #expect(abs(result.y - 0) < accuracy, "Negative y should clamp to 0, got \(result.y)")
    }

    @Test("Property 6 edge case: normalized coordinates above 1.0 are clamped to dimension")
    func displayPosition_aboveOneClamped() {
        // **Validates: Requirements 6.4, 6.5**
        let point = CGPoint(x: 1.5, y: 2.0)
        let displayWidth: CGFloat = 400
        let displayHeight: CGFloat = 600

        let result = CoordinateNormalizer.displayPosition(
            normalizedPoint: point,
            displayWidth: displayWidth,
            displayHeight: displayHeight
        )

        #expect(abs(result.x - displayWidth) < accuracy, "x above 1.0 should clamp to displayWidth, got \(result.x)")
        #expect(abs(result.y - displayHeight) < accuracy, "y above 1.0 should clamp to displayHeight, got \(result.y)")
    }

    @Test("Property 6 edge case: zero normalized coordinates produce zero display position")
    func displayPosition_zeroInput() {
        // **Validates: Requirements 6.4, 6.5**
        let point = CGPoint(x: 0, y: 0)
        let result = CoordinateNormalizer.displayPosition(
            normalizedPoint: point,
            displayWidth: 500,
            displayHeight: 800
        )

        #expect(abs(result.x - 0) < accuracy, "x=0 should produce 0, got \(result.x)")
        #expect(abs(result.y - 0) < accuracy, "y=0 should produce 0, got \(result.y)")
    }

    @Test("Property 6 edge case: normalized (1, 1) produces (width, height)")
    func displayPosition_maxInput() {
        // **Validates: Requirements 6.4, 6.5**
        let displayWidth: CGFloat = 375
        let displayHeight: CGFloat = 667

        let point = CGPoint(x: 1.0, y: 1.0)
        let result = CoordinateNormalizer.displayPosition(
            normalizedPoint: point,
            displayWidth: displayWidth,
            displayHeight: displayHeight
        )

        #expect(abs(result.x - displayWidth) < accuracy, "x=1 should produce displayWidth, got \(result.x)")
        #expect(abs(result.y - displayHeight) < accuracy, "y=1 should produce displayHeight, got \(result.y)")
    }

    @Test("Property 6 edge case: midpoint (0.5, 0.5) scales to center of display")
    func displayPosition_midpoint() {
        // **Validates: Requirements 6.4, 6.5**
        let displayWidth: CGFloat = 400
        let displayHeight: CGFloat = 800

        let point = CGPoint(x: 0.5, y: 0.5)
        let result = CoordinateNormalizer.displayPosition(
            normalizedPoint: point,
            displayWidth: displayWidth,
            displayHeight: displayHeight
        )

        #expect(abs(result.x - 200) < accuracy, "x=0.5 with width=400 should produce 200, got \(result.x)")
        #expect(abs(result.y - 400) < accuracy, "y=0.5 with height=800 should produce 400, got \(result.y)")
    }
}
