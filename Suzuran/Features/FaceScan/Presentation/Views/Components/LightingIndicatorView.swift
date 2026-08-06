import SwiftUI

struct LightingIndicatorView: View {
    let condition: LightingCondition

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: condition.iconName)
                .foregroundStyle(condition.color)

            Text(condition.message)
                .font(AppTypography.caption)
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.65))
        )
    }
}
