import SwiftUI

/// Report tab — placeholder.
struct ReportTabView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Segera Hadir",
                systemImage: "chart.xyaxis.line",
                description: Text("Fitur laporan perkembangan kulit akan segera tersedia.")
            )
            .navigationTitle("Report")
        }
    }
}
