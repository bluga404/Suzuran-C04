import SwiftUI

/// Full-screen detail view for a single sub-zone photo.
/// Displayed when the user taps a zone thumbnail on the result screen.
///
/// The key rendering challenge: `scaledToFit` inside a full-screen black container
/// leaves letterbox/pillarbox black bars. `FaceMaskScanVisualization` must be
/// constrained to the *actual image content rect* (not the full frame) so that
/// normalised bounding box coordinates align with pixels correctly.
struct ZoneDetailView: View {

    let subZone: SubZoneSummaryModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if let imageData = subZone.imageData,
                   let uiImage = UIImage(data: imageData) {
                    imageContentView(uiImage)
                } else {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "photo")
                            .font(Font.system(size: 56, weight: .regular))
                            .foregroundStyle(.secondary)
                        Text("Foto belum tersedia")
                            .font(Font.description)
                            .foregroundStyle(.secondary)
                    }
                }

                // Header overlay: back button + label + count badge
                headerOverlay
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Image Content View
    
    /// Renders the image with bounding boxes precisely on the content area.
    ///
    /// Uses `GeometryReader` to know the available space, computes the actual
    /// image rect after `scaledToFit` (accounting for pillarbox/letterbox gaps),
    /// then lays the `FaceMaskScanVisualization` on only that rect.
    @ViewBuilder
    private func imageContentView(_ uiImage: UIImage) -> some View {
        GeometryReader { geo in
            let imageSize   = uiImage.size
            let contentRect = scaledToFitRect(imageSize: imageSize, in: geo.size)

            ZStack(alignment: .topLeading) {
                // The actual photo
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)

                // Overlay constrained exactly to the image content rect
                FaceMaskScanVisualization(markers: subZone.markers)
                    .frame(width: contentRect.width, height: contentRect.height)
                    .offset(x: contentRect.minX, y: contentRect.minY)
                
                // Floating acne count badge over the photo
                VStack {
                    HStack {
                        Spacer()
                        Text("\(subZone.acneCount) Jerawat")
                            .font(.custom("AvenirNext-Medium", size: 13, relativeTo: .caption))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(Capsule().fill(.ultraThinMaterial))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(AppSpacing.md)
                    
                    Spacer()
                }
                .frame(width: contentRect.width, height: contentRect.height)
                .offset(x: contentRect.minX, y: contentRect.minY)
            }
        }
    }

    // MARK: - Geometry Helper

    /// Returns the CGRect inside `containerSize` that `scaledToFit` would render
    /// an image of `imageSize` into — i.e., the content area without black bars.
    private func scaledToFitRect(imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0,
              containerSize.width > 0, containerSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }

        let imageAspect     = imageSize.width  / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        let renderedSize: CGSize
        if imageAspect > containerAspect {
            // Image is wider → fit to container width, pillarbox top/bottom
            let w = containerSize.width
            renderedSize = CGSize(width: w, height: w / imageAspect)
        } else {
            // Image is taller (portrait) → fit to container height, letterbox left/right
            let h = containerSize.height
            renderedSize = CGSize(width: h * imageAspect, height: h)
        }

        let origin = CGPoint(
            x: (containerSize.width  - renderedSize.width)  / 2,
            y: (containerSize.height - renderedSize.height) / 2
        )
        return CGRect(origin: origin, size: renderedSize)
    }

    // MARK: - Header Overlay

    private var headerOverlay: some View {
        VStack {
            HStack(alignment: .center, spacing: AppSpacing.sm) {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(Font.bodyLarge)
                        .foregroundStyle(.white)
                        .padding(AppSpacing.sm)
                        .background(Circle().fill(.black.opacity(0.55)))
                }

                Text(subZone.label)
                    .font(Font.bodyLarge)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)

                Spacer()

                Text("\(subZone.acneCount) Jerawat")
                    .font(Font.metadata)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(Capsule().fill(.black.opacity(0.50)))
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, 56)
            .padding(.bottom, AppSpacing.sm)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.55), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Spacer()
        }
    }
}
