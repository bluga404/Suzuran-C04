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
                            .font(.custom("AvenirNext-Regular", size: 56, relativeTo: .largeTitle))
                            .foregroundStyle(.secondary)
                        Text("Foto belum tersedia")
                            .font(AppTypography.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(subZone.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
                
                // Native iOS 26 Toolbar Spacer
                if #available(iOS 26, *) {
                    ToolbarSpacer(.fixed)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
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
}
