import Testing
import CoreGraphics

@testable import Suzuran

/// Property-based tests for face position and proximity validation.
/// Feature: face-scan-redesign, Property 1: Face Position and Proximity Validation
///
/// **Validates: Requirements 3.2, 3.3**
///
/// These tests verify that the FaceValidation functions correctly determine:
/// - Position validity: face center must be within [0.20, 0.80] on both axes
/// - Proximity validity: face width must exceed 0.35 of the frame width
@Suite("FaceValidation Position & Proximity Property Tests")
struct FacePositionPropertyTests {

    /// Number of random iterations for property-based testing.
    private let iterations = 200

    /// Acceptable floating-point tolerance for boundary comparisons.
    private let epsilon: CGFloat = 1e-10

    // MARK: - Property 1a: Position Validation

    @Test("Property 1a: isPositionValid returns true iff midX ∈ [0.20, 0.80] AND midY ∈ [0.20, 0.80]")
    func positionValidation_property() {
        // **Validates: Requirements 3.2**
        //
        // For any CGRect with midX and midY in [0, 1], isPositionValid SHALL return
        // true if and only if midX >= 0.20 AND midX <= 0.80 AND midY >= 0.20 AND midY <= 0.80.

        for _ in 0..<iterations {
            let midX = CGFloat.random(in: 0...1)
            let midY = CGFloat.random(in: 0...1)
            let width = CGFloat.random(in: 0.01...0.99)
            let height = CGFloat.random(in: 0.01...0.99)

            // Construct a CGRect with the desired midX/midY
            let x = midX - width / 2
            let y = midY - height / 2
            let rect = CGRect(x: x, y: y, width: width, height: height)

            let result = FaceValidation.isPositionValid(boundingBox: rect)
            let expected = midX >= 0.20 && midX <= 0.80 && midY >= 0.20 && midY <= 0.80

            #expect(
                result == expected,
                "isPositionValid mismatch for midX=\(midX), midY=\(midY): got \(result), expected \(expected)"
            )
        }
    }

    // MARK: - Property 1a: Edge Cases

    @Test("Property 1a edge case: face center exactly at lower boundary (0.20, 0.20) is valid")
    func positionValidation_lowerBoundary() {
        // **Validates: Requirements 3.2**
        let rect = CGRect(x: 0.10, y: 0.10, width: 0.20, height: 0.20)
        // midX = 0.10 + 0.10 = 0.20, midY = 0.10 + 0.10 = 0.20
        #expect(FaceValidation.isPositionValid(boundingBox: rect) == true)
    }

    @Test("Property 1a edge case: face center exactly at upper boundary (0.80, 0.80) is valid")
    func positionValidation_upperBoundary() {
        // **Validates: Requirements 3.2**
        let rect = CGRect(x: 0.70, y: 0.70, width: 0.20, height: 0.20)
        // midX = 0.70 + 0.10 = 0.80, midY = 0.70 + 0.10 = 0.80
        #expect(FaceValidation.isPositionValid(boundingBox: rect) == true)
    }

    @Test("Property 1a edge case: face center just outside lower boundary is invalid")
    func positionValidation_justBelowLowerBoundary() {
        // **Validates: Requirements 3.2**
        // midX = 0.199, midY = 0.199 — both just below 0.20
        let rect = CGRect(x: 0.099, y: 0.099, width: 0.20, height: 0.20)
        #expect(FaceValidation.isPositionValid(boundingBox: rect) == false)
    }

    @Test("Property 1a edge case: face center just outside upper boundary is invalid")
    func positionValidation_justAboveUpperBoundary() {
        // **Validates: Requirements 3.2**
        // midX = 0.801, midY = 0.50 — midX just above 0.80
        let width: CGFloat = 0.20
        let rect = CGRect(x: 0.801 - width / 2, y: 0.40, width: width, height: 0.20)
        #expect(FaceValidation.isPositionValid(boundingBox: rect) == false)
    }

    @Test("Property 1a edge case: face at frame corners is invalid")
    func positionValidation_corners() {
        // **Validates: Requirements 3.2**
        // Top-left corner: midX ≈ 0.05, midY ≈ 0.05
        let topLeft = CGRect(x: 0.0, y: 0.0, width: 0.10, height: 0.10)
        #expect(FaceValidation.isPositionValid(boundingBox: topLeft) == false)

        // Bottom-right corner: midX ≈ 0.95, midY ≈ 0.95
        let bottomRight = CGRect(x: 0.90, y: 0.90, width: 0.10, height: 0.10)
        #expect(FaceValidation.isPositionValid(boundingBox: bottomRight) == false)
    }

    @Test("Property 1a edge case: face perfectly centered is valid")
    func positionValidation_centered() {
        // **Validates: Requirements 3.2**
        let rect = CGRect(x: 0.25, y: 0.25, width: 0.50, height: 0.50)
        // midX = 0.50, midY = 0.50
        #expect(FaceValidation.isPositionValid(boundingBox: rect) == true)
    }

    // MARK: - Property 1b: Proximity Validation

    @Test("Property 1b: isProximityValid returns true iff faceWidth > 0.35")
    func proximityValidation_property() {
        // **Validates: Requirements 3.3**
        //
        // For any face width in [0, 1], isProximityValid SHALL return true
        // if and only if width > 0.35.

        for _ in 0..<iterations {
            let width = CGFloat.random(in: 0...1)

            let result = FaceValidation.isProximityValid(faceWidth: width)
            let expected = width > 0.35

            #expect(
                result == expected,
                "isProximityValid mismatch for width=\(width): got \(result), expected \(expected)"
            )
        }
    }

    // MARK: - Property 1b: Edge Cases

    @Test("Property 1b edge case: width exactly at threshold (0.35) is invalid")
    func proximityValidation_exactThreshold() {
        // **Validates: Requirements 3.3**
        // Width == 0.35 exactly should return false (strict greater-than check)
        #expect(FaceValidation.isProximityValid(faceWidth: 0.35) == false)
    }

    @Test("Property 1b edge case: width just above threshold is valid")
    func proximityValidation_justAboveThreshold() {
        // **Validates: Requirements 3.3**
        #expect(FaceValidation.isProximityValid(faceWidth: 0.351) == true)
    }

    @Test("Property 1b edge case: width just below threshold is invalid")
    func proximityValidation_justBelowThreshold() {
        // **Validates: Requirements 3.3**
        #expect(FaceValidation.isProximityValid(faceWidth: 0.349) == false)
    }

    @Test("Property 1b edge case: zero width is invalid")
    func proximityValidation_zeroWidth() {
        // **Validates: Requirements 3.3**
        #expect(FaceValidation.isProximityValid(faceWidth: 0.0) == false)
    }

    @Test("Property 1b edge case: maximum width (1.0) is valid")
    func proximityValidation_maxWidth() {
        // **Validates: Requirements 3.3**
        #expect(FaceValidation.isProximityValid(faceWidth: 1.0) == true)
    }
}
