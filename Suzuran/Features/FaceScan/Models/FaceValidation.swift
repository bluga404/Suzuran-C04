import CoreGraphics
import Foundation

/// Pure validation functions for face scanning readiness checks.
struct FaceValidation {

    // MARK: - Position Validation

    /// Returns true if face center is within 30% of frame center (0.20–0.80 on both axes).
    ///
    /// - Parameter boundingBox: Face bounding box in normalized coordinates.
    /// - Returns: `true` if midX ∈ [0.20, 0.80] AND midY ∈ [0.20, 0.80].
    static func isPositionValid(boundingBox: CGRect) -> Bool {
        let midX = boundingBox.midX
        let midY = boundingBox.midY
        return midX >= 0.20 && midX <= 0.80 && midY >= 0.20 && midY <= 0.80
    }

    // MARK: - Proximity Validation

    /// Returns true if face width exceeds minimum proximity threshold (> 0.35).
    ///
    /// - Parameter faceWidth: Normalized face width (0–1 range).
    /// - Returns: `true` if width > 0.35.
    static func isProximityValid(faceWidth: CGFloat) -> Bool {
        return faceWidth > 0.35
    }

    // MARK: - Pose Matching

    /// Returns true if face pose matches the target angle.
    ///
    /// Thresholds per target:
    /// - Front: |yaw| < 0.30 AND |pitch| < 0.25
    /// - Left: yaw > 0.25 AND |pitch| < 0.25
    /// - Right: yaw < -0.25 AND |pitch| < 0.25
    ///
    /// - Parameters:
    ///   - yaw: Face yaw angle in radians.
    ///   - pitch: Face pitch angle in radians.
    ///   - target: The angle target to match against.
    /// - Returns: `true` if pose matches the target angle thresholds.
    static func isPoseMatched(yaw: Double, pitch: Double, target: FaceZone) -> Bool {
        let absYaw = abs(yaw)
        let absPitch = abs(pitch)

        switch target {
        case .front:
            return absYaw < 0.30 && absPitch < 0.25
        case .leftAngle:
            return yaw > 0.25 && absPitch < 0.25
        case .rightAngle:
            return yaw < -0.25 && absPitch < 0.25
        }
    }

    // MARK: - Stability Check

    /// Returns true if face movement between frames is below stability thresholds.
    ///
    /// Thresholds:
    /// - Position delta (hypot of midX/midY differences) < 0.045
    /// - Size delta (absolute width difference) < 0.05
    /// - Yaw delta < 0.10
    /// - Pitch delta < 0.10
    ///
    /// - Parameters:
    ///   - current: The current frame's face data.
    ///   - previous: The previous frame's face data.
    /// - Returns: `true` if all deltas are within stability thresholds.
    static func isStable(current: FaceFrameData, previous: FaceFrameData) -> Bool {
        // Position delta
        let deltaX = current.boundingBox.midX - previous.boundingBox.midX
        let deltaY = current.boundingBox.midY - previous.boundingBox.midY
        let positionDelta = hypot(deltaX, deltaY)

        guard positionDelta < 0.045 else { return false }

        // Size delta
        let sizeDelta = abs(current.boundingBox.width - previous.boundingBox.width)
        guard sizeDelta < 0.05 else { return false }

        // Yaw delta
        let currentYaw = current.yaw ?? 0.0
        let previousYaw = previous.yaw ?? 0.0
        let yawDelta = abs(currentYaw - previousYaw)
        guard yawDelta < 0.10 else { return false }

        // Pitch delta
        let currentPitch = current.pitch ?? 0.0
        let previousPitch = previous.pitch ?? 0.0
        let pitchDelta = abs(currentPitch - previousPitch)
        guard pitchDelta < 0.10 else { return false }

        return true
    }
}
