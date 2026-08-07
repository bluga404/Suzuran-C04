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
                let position = CoordinateNormalizer.displayPosition(
                    normalizedPoint: marker.normalizedPosition,
                    displayWidth: width,
                    displayHeight: height
                )

                Circle()
                    .fill(markerColor(for: marker.acneType))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
                    .position(x: position.x, y: position.y)
                    .accessibilityLabel("\(marker.acneType.displayName), confidence \(Int(marker.confidence * 100))%")
            }
        }
    }

    // MARK: - Color Mapping

    /// Maps acne type to a distinct marker color for visual differentiation.
    private func markerColor(for acneType: AcneType) -> Color {
        switch acneType {
        case .blackhead:
            return .brown
        case .cyst:
            return .red
        case .nodule:
            return .purple
        case .papule:
            return .orange
        case .pustule:
            return .yellow
        case .whitehead:
            return .white
        case .unknown:
            return .gray
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
