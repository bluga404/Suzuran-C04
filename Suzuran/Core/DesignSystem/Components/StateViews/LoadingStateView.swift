import SwiftUI

struct LoadingStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ProgressView()
                .tint(AppColor.accentPrimary)

            Text(title)
                .font(AppTypography.subtitle)
                .foregroundStyle(AppColor.textPrimary)

            Text(subtitle)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.lg)
    }
}
