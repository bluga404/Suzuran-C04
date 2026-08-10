import SwiftUI

struct TrackSkincareButton: View {
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                Text("Track Your Skincare")
                    .font(AppTypography.bodyBold)
            }
            .foregroundStyle(AppColor.accentPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        }
        .padding(.horizontal, AppSpacing.md)
        .accessibilityLabel("Track skincare products")
    }
}
