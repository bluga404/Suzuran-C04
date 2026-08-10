import SwiftUI

struct HistoryView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.accentPrimary)
            Text("Halo History")
                .font(AppTypography.title)
                .foregroundStyle(.primary)
            Text("Riwayat scan akan segera hadir")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    HistoryView()
}
