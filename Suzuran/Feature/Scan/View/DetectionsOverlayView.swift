import SwiftUI

/// Hosts the bounding box overlay for all acne detections.
/// Manages tap-to-select state and coordinates conversion from model space to screen space.
struct DetectionsOverlayView: View {
    let detections: [AcneDetection]
    let imageSize: CGSize
    let viewSize: CGSize

    @State private var selectedDetectionID: UUID?

    var body: some View {
        if detections.isEmpty {
            Color.clear
        } else {
            let transformer = CoordinateTransformer(imageSize: imageSize, viewSize: viewSize)

            ZStack {
                // Background tap area to deselect
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDetectionID = nil
                    }

                ForEach(detections) { detection in
                    BoundingBoxView(
                        detection: detection,
                        screenRect: transformer.convert(detection.box),
                        isSelected: selectedDetectionID == detection.id,
                        onTap: {
                            selectedDetectionID = detection.id
                        }
                    )
                }
            }
            .frame(width: viewSize.width, height: viewSize.height)
        }
    }
}
