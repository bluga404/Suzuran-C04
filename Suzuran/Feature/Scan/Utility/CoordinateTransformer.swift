import CoreGraphics

/// A pure value type that converts YOLO model-space bounding boxes (640×640)
/// to screen-space coordinates, accounting for `.scaledToFit()` letterboxing.
struct CoordinateTransformer {
    /// The model input dimension (YOLO uses 640×640).
    let modelSize: CGFloat = 640

    /// The original captured image pixel dimensions.
    let imageSize: CGSize

    /// The GeometryReader-reported container size on screen.
    let viewSize: CGSize

    // MARK: - Computed Properties

    /// Uniform scale factor matching `.scaledToFit()` behavior.
    var scaleFactor: CGFloat {
        min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
    }

    /// The rendered image size after applying the scale factor.
    var actualImageSize: CGSize {
        CGSize(
            width: imageSize.width * scaleFactor,
            height: imageSize.height * scaleFactor
        )
    }

    /// The letterbox offset that centers the image within the view.
    var offset: CGPoint {
        CGPoint(
            x: (viewSize.width - actualImageSize.width) / 2,
            y: (viewSize.height - actualImageSize.height) / 2
        )
    }

    // MARK: - Conversion

    /// Converts a model-space CGRect (in 640×640 coordinates) to a screen-space CGRect.
    ///
    /// Steps:
    /// 1. Normalize — divide each component by modelSize (640)
    /// 2. Scale — multiply by actualImageSize
    /// 3. Offset — add letterbox offset
    func convert(_ modelRect: CGRect) -> CGRect {
        // 1. Normalize to 0.0–1.0 range
        let normX = modelRect.origin.x / modelSize
        let normY = modelRect.origin.y / modelSize
        let normW = modelRect.width / modelSize
        let normH = modelRect.height / modelSize

        // 2. Scale to actual rendered image dimensions
        let scaledX = normX * actualImageSize.width
        let scaledY = normY * actualImageSize.height
        let scaledW = normW * actualImageSize.width
        let scaledH = normH * actualImageSize.height

        // 3. Apply letterbox offset
        return CGRect(
            x: offset.x + scaledX,
            y: offset.y + scaledY,
            width: scaledW,
            height: scaledH
        )
    }
}
