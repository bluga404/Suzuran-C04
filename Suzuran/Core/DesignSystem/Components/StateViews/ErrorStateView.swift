import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    var primaryActionTitle: String
    var onPrimaryAction: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 38))
                .foregroundStyle(AppColor.accentDanger)

            Text(title)
                .font(AppTypography.subtitle)
                .foregroundStyle(AppColor.textPrimary)

            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)

            PrimaryButton(title: primaryActionTitle, action: onPrimaryAction)
                .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.lg)
    }
}
