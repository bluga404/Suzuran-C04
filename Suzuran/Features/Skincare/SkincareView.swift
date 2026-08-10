import SwiftUI

struct SkincareView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.accentPrimary)
            Text("Halo Skincare")
                .font(AppTypography.title)
                .foregroundStyle(.primary)
            Text("Fitur tracking skincare akan segera hadir")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    SkincareView()
}
