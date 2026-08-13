import XCTest
@testable import Suzuran

/// Property-based tests for face stability validation.
/// Feature: face-scan-redesign, Property 3: Face Stability Validation
///
/// **Validates: Requirements 3.7**
///
/// For any pair of consecutive FaceFrameData values, the stability check SHALL return
/// true if and only if:
/// - Position delta (hypot of midX/midY differences) < 0.045
/// - Size delta (absolute width difference) < 0.05
/// - Yaw delta < 0.10
/// - Pitch delta < 0.10
final class FaceStabilityPropertyTests: XCTestCase {

    /// Number of random iterations for property-based testing.
    private let iterations = 200

    // MARK: - Property 3: Face Stability Validation

    func testStabilityValidation_property() {
        // **Validates: Requirements 3.7**
        //
        // Generate random pairs of FaceFrameData with varying deltas and assert
        // that isStable returns true iff ALL threshold conditions are met.

        for _ in 0..<iterations {
            // Generate random base frame values
            let prevMidX = CGFloat.random(in: 0.2...0.8)
            let prevMidY = CGFloat.random(in: 0.2...0.8)
            let prevWidth = CGFloat.random(in: 0.2...0.6)
            let prevHeight = CGFloat.random(in: 0.2...0.6)
            let prevYaw = Double.random(in: -1.0...1.0)
            let prevPitch = Double.random(in: -1.0...1.0)

            let prevRect = CGRect(
                x: prevMidX - prevWidth / 2,
                y: prevMidY - prevHeight / 2,
                width: prevWidth,
                height: prevHeight
            )
            let previous = FaceFrameData(boundingBox: prevRect, yaw: prevYaw, pitch: prevPitch)

            // Generate random current frame with small deltas that span both sides of thresholds
            let curMidX = prevMidX + CGFloat.random(in: -0.06...0.06)
            let curMidY = prevMidY + CGFloat.random(in: -0.06...0.06)
            let curWidth = prevWidth + CGFloat.random(in: -0.07...0.07)
            let curHeight = prevHeight + CGFloat.random(in: -0.07...0.07)
            let curYaw = prevYaw + Double.random(in: -0.15...0.15)
            let curPitch = prevPitch + Double.random(in: -0.15...0.15)

            let curRect = CGRect(
                x: curMidX - curWidth / 2,
                y: curMidY - curHeight / 2,
                width: curWidth,
                height: curHeight
            )
            let current = FaceFrameData(boundingBox: curRect, yaw: curYaw, pitch: curPitch)

            // Compute expected result using the same logic as the implementation
            let posDelta = hypot(curMidX - prevMidX, curMidY - prevMidY)
            let sizeDelta = abs(curWidth - prevWidth)
            let yawDelta = abs(curYaw - prevYaw)
            let pitchDelta = abs(curPitch - prevPitch)

            let expected = posDelta < 0.045
                && sizeDelta < 0.05
                && yawDelta < 0.10
                && pitchDelta < 0.10

            let actual = FaceValidation.isStable(current: current, previous: previous)

            XCTAssertEqual(
                actual,
                expected,
                """
                Stability mismatch:
                  posDelta=\(posDelta) (threshold 0.045),
                  sizeDelta=\(sizeDelta) (threshold 0.05),
                  yawDelta=\(yawDelta) (threshold 0.10),
                  pitchDelta=\(pitchDelta) (threshold 0.10)
                  expected=\(expected), actual=\(actual)
                """
            )
        }
    }

    // MARK: - Edge Cases

    func testStability_identicalFrames_isAlwaysStable() {
        // **Validates: Requirements 3.7**
        // When previous and current frames are identical, all deltas are 0 and isStable must return true.

        for _ in 0..<50 {
            let midX = CGFloat.random(in: 0.1...0.9)
            let midY = CGFloat.random(in: 0.1...0.9)
            let width = CGFloat.random(in: 0.1...0.8)
            let height = CGFloat.random(in: 0.1...0.8)
            let yaw = Double.random(in: -1.0...1.0)
            let pitch = Double.random(in: -1.0...1.0)

            let rect = CGRect(x: midX - width / 2, y: midY - height / 2, width: width, height: height)
            let frame = FaceFrameData(boundingBox: rect, yaw: yaw, pitch: pitch)

            XCTAssertTrue(
                FaceValidation.isStable(current: frame, previous: frame),
                "Identical frames must always be stable"
            )
        }
    }

    func testStability_nilYawPitch_treatedAsZero() {
        // **Validates: Requirements 3.7**
        // When yaw/pitch are nil, they should be treated as 0. Two nil frames should be stable.

        let rect = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)
        let frameWithNils = FaceFrameData(boundingBox: rect, yaw: nil, pitch: nil)
        let frameWithZeros = FaceFrameData(boundingBox: rect, yaw: 0.0, pitch: 0.0)

        XCTAssertTrue(
            FaceValidation.isStable(current: frameWithNils, previous: frameWithNils),
            "Two frames with nil yaw/pitch should be stable (both treated as 0)"
        )
        XCTAssertTrue(
            FaceValidation.isStable(current: frameWithNils, previous: frameWithZeros),
            "Nil yaw/pitch should match zero yaw/pitch"
        )
    }

    func testStability_positionDeltaExactlyAtThreshold_isNotStable() {
        // **Validates: Requirements 3.7**
        // Position delta exactly at 0.045 should NOT be stable (strict < comparison).

        let prevRect = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)
        // Move midX by exactly 0.045 (midY stays same, so hypot = 0.045)
        let curRect = CGRect(x: 0.3 + 0.045, y: 0.3, width: 0.4, height: 0.4)

        let previous = FaceFrameData(boundingBox: prevRect, yaw: 0.0, pitch: 0.0)
        let current = FaceFrameData(boundingBox: curRect, yaw: 0.0, pitch: 0.0)

        XCTAssertFalse(
            FaceValidation.isStable(current: current, previous: previous),
            "Position delta exactly at threshold (0.045) should NOT be stable"
        )
    }

    func testStability_sizeDeltaExactlyAtThreshold_isNotStable() {
        // **Validates: Requirements 3.7**
        // Size delta exactly at 0.05 should NOT be stable (strict < comparison).

        let prevRect = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)
        let curRect = CGRect(x: 0.3, y: 0.3, width: 0.45, height: 0.4)

        let previous = FaceFrameData(boundingBox: prevRect, yaw: 0.0, pitch: 0.0)
        let current = FaceFrameData(boundingBox: curRect, yaw: 0.0, pitch: 0.0)

        XCTAssertFalse(
            FaceValidation.isStable(current: current, previous: previous),
            "Size delta exactly at threshold (0.05) should NOT be stable"
        )
    }

    func testStability_yawDeltaExactlyAtThreshold_isNotStable() {
        // **Validates: Requirements 3.7**
        // Yaw delta exactly at 0.10 should NOT be stable (strict < comparison).

        let rect = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)

        let previous = FaceFrameData(boundingBox: rect, yaw: 0.0, pitch: 0.0)
        let current = FaceFrameData(boundingBox: rect, yaw: 0.10, pitch: 0.0)

        XCTAssertFalse(
            FaceValidation.isStable(current: current, previous: previous),
            "Yaw delta exactly at threshold (0.10) should NOT be stable"
        )
    }

    func testStability_pitchDeltaExactlyAtThreshold_isNotStable() {
        // **Validates: Requirements 3.7**
        // Pitch delta exactly at 0.10 should NOT be stable (strict < comparison).

        let rect = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)

        let previous = FaceFrameData(boundingBox: rect, yaw: 0.0, pitch: 0.0)
        let current = FaceFrameData(boundingBox: rect, yaw: 0.0, pitch: 0.10)

        XCTAssertFalse(
            FaceValidation.isStable(current: current, previous: previous),
            "Pitch delta exactly at threshold (0.10) should NOT be stable"
        )
    }
}
