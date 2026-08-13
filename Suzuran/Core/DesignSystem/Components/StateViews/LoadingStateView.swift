import SwiftUI

struct LoadingStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ProgressView()
                .tint(AppColor.accentPrimary)

            Text(title)
                .font(Font.bodyParagraph)
                .foregroundStyle(AppColor.textPrimary)

            Text(subtitle)
                .font(Font.description)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.lg)
    }
}
