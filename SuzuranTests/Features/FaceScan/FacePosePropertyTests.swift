import XCTest
@testable import Suzuran

/// Property-based tests for face pose matching validation.
/// Feature: face-scan-redesign, Property 2: Pose Match Per Angle Target
///
/// **Validates: Requirements 3.4, 3.5, 3.6**
///
/// These tests verify that the `FaceValidation.isPoseMatched` function
/// correctly identifies whether a given (yaw, pitch) pair matches the
/// target angle thresholds as specified in the design document:
/// - Front: |yaw| < 0.30 AND |pitch| < 0.25
/// - Left: yaw > 0.25 AND |pitch| < 0.25
/// - Right: yaw < -0.25 AND |pitch| < 0.25
final class FacePosePropertyTests: XCTestCase {

    /// Number of random iterations per property test.
    private let iterations = 200

    // MARK: - Property 2: Pose Match Per Angle Target

    /// Property test for front angle pose matching.
    /// For any random (yaw, pitch) in [-π/2, π/2], isPoseMatched with target .front
    /// SHALL return true iff |yaw| < 0.30 AND |pitch| < 0.25.
    ///
    /// **Validates: Requirements 3.4**
    func testPoseMatchFront_property() {
        for _ in 0..<iterations {
            let yaw = Double.random(in: -Double.pi / 2...Double.pi / 2)
            let pitch = Double.random(in: -Double.pi / 2...Double.pi / 2)

            let expected = abs(yaw) < 0.30 && abs(pitch) < 0.25
            XCTAssertEqual(
                FaceValidation.isPoseMatched(yaw: yaw, pitch: pitch, target: .front),
                expected,
                "Front failed for yaw=\(yaw), pitch=\(pitch)"
            )
        }
    }

    /// Property test for left angle pose matching.
    /// For any random (yaw, pitch) in [-π/2, π/2], isPoseMatched with target .leftAngle
    /// SHALL return true iff yaw > 0.25 AND |pitch| < 0.25.
    ///
    /// **Validates: Requirements 3.5**
    func testPoseMatchLeft_property() {
        for _ in 0..<iterations {
            let yaw = Double.random(in: -Double.pi / 2...Double.pi / 2)
            let pitch = Double.random(in: -Double.pi / 2...Double.pi / 2)

            let expected = yaw > 0.25 && abs(pitch) < 0.25
            XCTAssertEqual(
                FaceValidation.isPoseMatched(yaw: yaw, pitch: pitch, target: .leftAngle),
                expected,
                "Left failed for yaw=\(yaw), pitch=\(pitch)"
            )
        }
    }

    /// Property test for right angle pose matching.
    /// For any random (yaw, pitch) in [-π/2, π/2], isPoseMatched with target .rightAngle
    /// SHALL return true iff yaw < -0.25 AND |pitch| < 0.25.
    ///
    /// **Validates: Requirements 3.6**
    func testPoseMatchRight_property() {
        for _ in 0..<iterations {
            let yaw = Double.random(in: -Double.pi / 2...Double.pi / 2)
            let pitch = Double.random(in: -Double.pi / 2...Double.pi / 2)

            let expected = yaw < -0.25 && abs(pitch) < 0.25
            XCTAssertEqual(
                FaceValidation.isPoseMatched(yaw: yaw, pitch: pitch, target: .rightAngle),
                expected,
                "Right failed for yaw=\(yaw), pitch=\(pitch)"
            )
        }
    }
}
