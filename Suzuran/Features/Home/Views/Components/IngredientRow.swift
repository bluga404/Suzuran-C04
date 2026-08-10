import SwiftUI

/// A single row inside the Ingredients card, showing the ingredient name,
/// explanation, and whether it was found in the user's scanned products.
struct IngredientRow: View {
    let recommendation: IngredientRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(recommendation.ingredient.displayName)
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColor.textPrimary)

            Text(recommendation.explanation)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)

            statusPill
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusPill: some View {
        let text: String = {
            switch recommendation.status {
            case .notFound:
                return "Not found in your scanned products"
            case .found(let productName):
                return "In your routine - \(productName)"
            }
        }()

        Text(text)
            .font(AppTypography.caption)
            .foregroundStyle(AppColor.textSecondary)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background(AppColor.borderSubtle.opacity(0.5))
            .clipShape(Capsule())
    }
}

#Preview("Not Found") {
    IngredientRow(
        recommendation: IngredientRecommendation(
            id: UUID(),
            ingredient: Ingredient(name: "niacinamide", displayName: "Niacinamide"),
            explanation: "Helps control sebum production and repair the skin barrier",
            status: .notFound
        )
    )
    .padding()
}

#Preview("Found") {
    IngredientRow(
        recommendation: IngredientRecommendation(
            id: UUID(),
            ingredient: Ingredient(name: "salicylic acid", displayName: "Salicylic Acid"),
            explanation: "Exfoliant that helps unclog pores",
            status: .found(productName: "Facewash")
        )
    )
    .padding()
}
