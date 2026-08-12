import SwiftUI

/// Acne marker overlay that positions detection markers on a captured face image.
///
/// Uses `GeometryReader` to obtain the actual rendered dimensions, then scales
/// each marker's normalized position via `CoordinateNormalizer.displayPosition`
/// to place colored circles at the correct display coordinates.
struct FaceMaskScanVisualization: View {
    let markers: [MarkerModel]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ForEach(markers) { marker in
                let rect = CoordinateNormalizer.displayRect(
                    normalizedRect: marker.normalizedBoundingBox,
                    displayWidth: width,
                    displayHeight: height
                )

                Rectangle()
                    .stroke(marker.acneType.color, lineWidth: 2)
                    .background(marker.acneType.color.opacity(0.2))
                    .frame(width: rect.width, height: rect.height)
                    // .position takes the center of the view, so we provide the center of the rect
                    .position(x: rect.midX, y: rect.midY)
                    .accessibilityLabel("\(marker.acneType.displayName), confidence \(Int(marker.confidence * 100))%")
            }
        }
    }
}

#Preview {
    let sampleMarkers: [MarkerModel] = [
        MarkerModel(
            id: UUID(),
            acneType: .papule,
            confidence: 0.85,
            normalizedPosition: CGPoint(x: 0.3, y: 0.4)
        ),
        MarkerModel(
            id: UUID(),
            acneType: .cyst,
            confidence: 0.72,
            normalizedPosition: CGPoint(x: 0.6, y: 0.5)
        ),
        MarkerModel(
            id: UUID(),
            acneType: .blackhead,
            confidence: 0.55,
            normalizedPosition: CGPoint(x: 0.5, y: 0.7)
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
