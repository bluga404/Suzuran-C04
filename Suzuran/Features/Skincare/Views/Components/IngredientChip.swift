import SwiftUI

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

            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isMatched ? AppColor.accentPrimary.opacity(0.8) : AppColor.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Capsule()
                .fill(isMatched ? AppColor.accentPrimary.opacity(0.08) : AppColor.surfacePrimary)
        )
        .overlay(
            Capsule()
                .stroke(isMatched ? AppColor.accentPrimary : AppColor.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: AppSpacing.sm) {
        IngredientChip(name: "Salicylic Acid", isMatched: true)
        IngredientChip(name: "Aqua", isMatched: false)
        IngredientChip(name: "Niacinamide", isMatched: true, onDelete: {})
        IngredientChip(name: "Glycerin", isMatched: false, onDelete: {})
    }
    .padding()
    .background(AppColor.backgroundPrimary)
}
