import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    var actionTitle: String?
    var onAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(AppColor.textSecondary)

            Text(title)
                .font(Font.bodyParagraph)
                .foregroundStyle(AppColor.textPrimary)

            Text(message)
                .font(Font.description)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let onAction {
                PrimaryButton(title: actionTitle, style: .bordered, action: onAction)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.lg)
    }
}
