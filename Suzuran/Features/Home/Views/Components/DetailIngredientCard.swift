import SwiftUI

/// An expandable accordion card displaying an ingredient recommendation.
/// All cards start in collapsed state by default. Tapping toggles only that card.
struct DetailIngredientCard: View {
    let recommendation: IngredientRecommendation
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(recommendation.ingredient.displayName)
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            if isExpanded {
                Text(recommendation.explanation)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        .padding(.horizontal, AppSpacing.md)
    }
}
