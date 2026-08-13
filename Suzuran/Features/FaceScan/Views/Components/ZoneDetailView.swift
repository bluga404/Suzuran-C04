import SwiftUI

/// Detail view for a single sub-zone photo, presented as a sheet.
/// The sheet height adapts to the photo's aspect ratio so the image
/// fills the entire visible area with no empty gaps.
struct ZoneDetailView: View {

    let subZone: SubZoneSummaryModel
    let onDismiss: () -> Void

    /// The image decoded once for sizing + display.
    private var uiImage: UIImage? {
        guard let data = subZone.imageData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                if let uiImage {
                    imageContentView(uiImage, in: geo.size)
                } else {
                    placeholderView
                }

                // Header overlay: back button + label + count badge
                headerOverlay
            }
        }
        .ignoresSafeArea()
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sheet Height

    /// Computes the ideal sheet height so the image fills edge-to-edge.
    /// Accounts for the drag indicator (~20pt) that sits above the content.
    private var sheetHeight: CGFloat {
        guard let uiImage, uiImage.size.width > 0 else {
            return UIScreen.main.bounds.height * 0.5
        }
        let screenWidth = UIScreen.main.bounds.width
        let imageHeight = screenWidth * (uiImage.size.height / uiImage.size.width)
        let maxHeight = UIScreen.main.bounds.height * 0.92
        return min(imageHeight, maxHeight)
    }

    // MARK: - Image Content View

    @ViewBuilder
    private func imageContentView(_ image: UIImage, in size: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
            .overlay(
                FaceMaskScanVisualization(markers: subZone.markers)
            )
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "photo")
                .font(Font.system(size: 56, weight: .regular))
                .foregroundStyle(.secondary)
            Text("Foto belum tersedia")
                .font(Font.description)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

                Text("\(subZone.acneCount) Acne")
                    .font(Font.metadata)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(Capsule().fill(.black.opacity(0.50)))
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.lg)
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
