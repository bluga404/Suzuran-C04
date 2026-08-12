import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Lightweight payload for navigating to the full photo detail view.
struct PhotoDetailPayload: Identifiable, Hashable {
    let id = UUID()
    let imageData: Data?
    let uiImage: UIImage?
    let title: String
    let dateText: String

    init(imageData: Data? = nil, uiImage: UIImage? = nil, title: String, dateText: String) {
        self.imageData = imageData
        self.uiImage = uiImage
        self.title = title
        self.dateText = dateText
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Shared full-screen photo detail preview page.
/// Displays a face scan photo centered with subtle shadow and a bottom pill badge showing title and date.
struct FullPhotoDetailView: View {
    let imageData: Data?
    let uiImage: UIImage?
    let title: String
    let dateText: String

    init(imageData: Data? = nil, uiImage: UIImage? = nil, title: String, dateText: String) {
        self.imageData = imageData
        self.uiImage = uiImage
        self.title = title
        self.dateText = dateText
    }

    init(payload: PhotoDetailPayload) {
        self.imageData = payload.imageData
        self.uiImage = payload.uiImage
        self.title = payload.title
        self.dateText = payload.dateText
    }

    var displayUIImage: UIImage? {
        if let data = imageData, let img = UIImage(data: data) {
            return img
        }
        return uiImage
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                if let image = displayUIImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 16)
                } else {
                    ContentUnavailableView(
                        "No Image Available",
                        systemImage: "person.crop.rectangle",
                        description: Text("No photo data found for this scan record.")
                    )
                }

                Spacer()

                // Date & Area Badge
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text(dateText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
