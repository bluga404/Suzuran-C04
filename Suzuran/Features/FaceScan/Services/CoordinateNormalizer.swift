import CoreGraphics

/// Pure function utility responsible for converting YOLO output coordinates
/// to display-ready normalized values.
///
/// Coordinate system note: Both CGImage capture (top-left origin) and YOLO model
/// output (top-left origin) share the same coordinate system — NO Y-axis flip is applied.
struct CoordinateNormalizer {

    /// The YOLO model input image size in pixels (640×640).
    static let modelInputSize: CGFloat = 640.0

    // MARK: - Normalization

    /// Converts YOLO pixel-space bounding box coordinates [x1, y1, x2, y2] to a
    /// normalized midpoint in [0, 1] space.
    ///
    /// - Parameters:
    ///   - x1: Left edge x-coordinate in pixel space (0–640).
    ///   - y1: Top edge y-coordinate in pixel space (0–640).
    ///   - x2: Right edge x-coordinate in pixel space (0–640).
    ///   - y2: Bottom edge y-coordinate in pixel space (0–640).
    /// - Returns: A `CGPoint` representing the clamped normalized midpoint.
    static func normalize(
        x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat
    ) -> CGPoint {
        let midX = ((x1 + x2) / 2.0) / modelInputSize
        let midY = ((y1 + y2) / 2.0) / modelInputSize
        // No Y-flip: both CGImage and YOLO use top-left origin
        return CGPoint(x: clamp(midX), y: clamp(midY))
    }

    // MARK: - Clamping

    /// Clamps a normalized coordinate value to the valid range [0, 1].
    ///
    /// - Parameter value: The value to clamp.
    /// - Returns: The value constrained to [0, 1].
    static func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, 0.0), 1.0)
    }

    // MARK: - Display Mapping

    /// Scales a normalized point to actual display pixel dimensions, clamping
    /// inputs to [0, 1] before scaling.
    ///
    /// - Parameters:
    ///   - normalizedPoint: A point with x and y in normalized space (ideally 0–1).
    ///   - displayWidth: The width of the display area in points/pixels.
    ///   - displayHeight: The height of the display area in points/pixels.
    /// - Returns: A `CGPoint` in display coordinates within [0, displayWidth] × [0, displayHeight].
    static func displayPosition(
        normalizedPoint: CGPoint,
        displayWidth: CGFloat,
        displayHeight: CGFloat
    ) -> CGPoint {
        let x = clamp(normalizedPoint.x) * displayWidth
        let y = clamp(normalizedPoint.y) * displayHeight
        return CGPoint(x: x, y: y)
    }

    /// Scales a normalized rect to actual display pixel dimensions, clamping
    /// inputs to [0, 1] before scaling.
    ///
    /// - Parameters:
    ///   - normalizedRect: A rect with coordinates in normalized space (0–1).
    ///   - displayWidth: The width of the display area in points/pixels.
    ///   - displayHeight: The height of the display area in points/pixels.
    /// - Returns: A `CGRect` in display coordinates.
    static func displayRect(
        normalizedRect: CGRect,
        displayWidth: CGFloat,
        displayHeight: CGFloat
    ) -> CGRect {
        let x = clamp(normalizedRect.minX) * displayWidth
        let y = clamp(normalizedRect.minY) * displayHeight
        // Note: Width and height shouldn't strictly be clamped to 1 if they originate from valid x1,y1,x2,y2, 
        // but for safety we can just scale them directly.
        let w = min(normalizedRect.width, 1.0 - clamp(normalizedRect.minX)) * displayWidth
        let h = min(normalizedRect.height, 1.0 - clamp(normalizedRect.minY)) * displayHeight
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
