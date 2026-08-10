import SwiftUI

/// Acne detection overlay that renders YOLO bounding-box rectangles on a captured face image.
///
/// Uses `GeometryReader` to obtain the actual rendered dimensions, then scales
/// each marker's `normalizedBoundingBox` to display-space coordinates and draws
/// a coloured stroke rectangle — matching the YOLO detection output exactly.
struct FaceMaskScanVisualization: View {
    let markers: [MarkerModel]

    var body: some View {
        GeometryReader { geometry in
            let width  = geometry.size.width
            let height = geometry.size.height

            ForEach(markers) { marker in
                let box = displayRect(
                    normalized: marker.normalizedBoundingBox,
                    displayWidth: width,
                    displayHeight: height
                )

                Rectangle()
                    .stroke(markerColor(for: marker.acneType), lineWidth: 1.5)
                    .frame(width: box.width, height: box.height)
                    .position(x: box.midX, y: box.midY)
                    .accessibilityLabel(
                        "\(marker.acneType.displayName), confidence \(Int(marker.confidence * 100))%"
                    )
            }
        }
    }

    // MARK: - Coordinate Conversion

    /// Converts a normalised bounding box (0–1, top-left origin) to display-space CGRect.
    private func displayRect(
        normalized rect: CGRect,
        displayWidth: CGFloat,
        displayHeight: CGFloat
    ) -> CGRect {
        CGRect(
            x: rect.origin.x * displayWidth,
            y: rect.origin.y * displayHeight,
            width: rect.width  * displayWidth,
            height: rect.height * displayHeight
        )
    }

    // MARK: - Color

    /// Uses the shared `AcneType.color` so bounding boxes match the Type list.
    private func markerColor(for acneType: AcneType) -> Color {
        acneType.color
    }
}

#Preview {
    let sampleMarkers: [MarkerModel] = [
        MarkerModel(
            id: UUID(),
            acneType: .papule,
            confidence: 0.85,
            normalizedBoundingBox: CGRect(x: 0.20, y: 0.30, width: 0.12, height: 0.10)
        ),
        MarkerModel(
            id: UUID(),
            acneType: .cyst,
            confidence: 0.72,
            normalizedBoundingBox: CGRect(x: 0.55, y: 0.45, width: 0.10, height: 0.08)
        ),
        MarkerModel(
            id: UUID(),
            acneType: .blackhead,
            confidence: 0.55,
            normalizedBoundingBox: CGRect(x: 0.40, y: 0.65, width: 0.08, height: 0.06)
        ),
    ]

    ZStack {
        Rectangle()
            .fill(.gray.opacity(0.3))
            .frame(width: 300, height: 400)

        FaceMaskScanVisualization(markers: sampleMarkers)
            .frame(width: 300, height: 400)
    }
}
