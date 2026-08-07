import CoreGraphics

/// Represents a single frame's face detection data from the Vision framework.
struct FaceFrameData {
    /// Face bounding box in Vision normalized coordinates (origin bottom-left, 0–1 range)
    let boundingBox: CGRect
    /// Face yaw angle in radians (nil if not detected)
    let yaw: Double?
    /// Face pitch angle in radians (nil if not detected)
    let pitch: Double?
}
