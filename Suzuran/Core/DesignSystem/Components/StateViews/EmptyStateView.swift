import SwiftUI

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String
    var actionTitle: String?
    var onAction: (() -> Void)?

    init(
        iconName: String = "tray",
        title: String,
        message: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.onAction = onAction
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer(minLength: AppSpacing.lg)

            ZStack {
                Circle()
                    .fill(AppColor.buttonPrimaryPurple.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(AppColor.buttonPrimaryPurple)
            }

            Text(title)
                .font(Font.bodyParagraph)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(Font.metadata)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)

            if let actionTitle, let onAction {
                Button(action: onAction) {
                    Text(actionTitle)
                        .font(Font.description)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColor.buttonPrimaryPurple)
                        .foregroundStyle(Color.white)
                        .cornerRadius(AppCornerRadius.md)
                }
                .padding(.top, AppSpacing.xs)
            }

            Spacer(minLength: AppSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }
}
