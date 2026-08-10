import SwiftUI

struct SkincareView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "leaf.fill")
                .font(.custom("AvenirNext-Regular", size: 48, relativeTo: .largeTitle))
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
