import SwiftUI

/// Compact ingredient token with an optional, HIG-sized delete control.
struct IngredientChip: View {
    let name: String
    var isMatched: Bool = false
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Text(name)
                .font(AppTypography.caption)
                .fontWeight(isMatched ? .semibold : .regular)
                .foregroundStyle(isMatched ? AppColor.accentPrimary : AppColor.textPrimary)
                .lineLimit(1)

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(AppTypography.caption)
                        .foregroundStyle(isMatched ? AppColor.accentPrimary : AppColor.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hapus \(name)")
            }
        }
        .padding(.leading, AppSpacing.sm)
        .padding(.trailing, onDelete == nil ? AppSpacing.sm : AppSpacing.xxs)
        .frame(minHeight: 44)
        .background(
            Capsule().fill(isMatched ? AppColor.accentPrimary.opacity(0.08) : AppColor.surfacePrimary)
        )
        .overlay(
            Capsule().stroke(isMatched ? AppColor.accentPrimary : AppColor.borderSubtle, lineWidth: 1)
        )
    }
}
