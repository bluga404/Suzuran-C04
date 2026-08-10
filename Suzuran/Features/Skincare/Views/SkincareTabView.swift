import SwiftUI

/// Skincare tab — placeholder.
struct SkincareTabView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Segera Hadir",
                systemImage: "sparkles",
                description: Text("Fitur rekomendasi skincare akan segera tersedia.")
            )
            .navigationTitle("Skincare")
        }
    }
}
