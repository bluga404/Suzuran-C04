import SwiftUI

/// Renders a single bounding box overlay for an acne detection.
/// Displays a colored rounded rectangle, a label badge, and (when selected) a confidence badge.
struct BoundingBoxView: View {
    let detection: AcneDetection
    let screenRect: CGRect
    let isSelected: Bool
    let onTap: () -> Void

    private var labelColor: Color {
        AcneLabelColor.color(for: detection.label)
    }

    private var confidenceText: String {
        String(format: "%.1f%%", detection.confidence * 100)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Bounding box: stroked rounded rectangle
            RoundedRectangle(cornerRadius: 4)
                .stroke(labelColor, lineWidth: 2)

            // Label badge positioned above the top-left of the box
            VStack(alignment: .leading, spacing: 2) {
                labelBadge
                    .offset(y: -20)

                if isSelected {
                    confidenceBadge
                        .offset(y: -20)
                }
            }
        }
        .frame(width: screenRect.width, height: screenRect.height)
        .position(x: screenRect.midX, y: screenRect.midY)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    // MARK: - Subviews

    /// Small capsule badge showing the acne label text
    private var labelBadge: some View {
        Text(detection.label)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(labelColor.opacity(0.8))
            )
    }

    /// Confidence percentage badge shown only when the box is selected
    private var confidenceBadge: some View {
        Text(confidenceText)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.7))
            )
    }
}
