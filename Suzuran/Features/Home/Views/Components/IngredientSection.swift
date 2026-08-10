import SwiftUI

/// Displays the ingredient recommendations as a single card consistent with
/// the Skin Condition and Most Detected sections: an "INGREDIENTS" header with
/// an info button, followed by ingredient rows (or a placeholder when no data).
struct IngredientSection: View {
    let recommendations: [IngredientRecommendation]
    let showEmptyState: Bool
    var onInfoTap: () -> Void = {}

    private var visibleRecommendations: [IngredientRecommendation] {
        Array(recommendations.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("INGREDIENTS")
                        .font(AppTypography.caption)
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: onInfoTap) {
                        Image(systemName: "info.circle")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Ingredients information")
                }

                if visibleRecommendations.isEmpty && showEmptyState {
                    Text("Scan your skincare products to get ingredient recommendations")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(visibleRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                        IngredientRow(recommendation: recommendation)
                        if index < visibleRecommendations.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

#Preview("With Recommendations") {
    IngredientSection(
        recommendations: [
            IngredientRecommendation(
                id: UUID(),
                ingredient: Ingredient(name: "niacinamide", displayName: "Niacinamide"),
                explanation: "Helps control sebum production and reduce inflammation",
                status: .notFound
            ),
            IngredientRecommendation(
                id: UUID(),
                ingredient: Ingredient(name: "salicylic acid", displayName: "Salicylic Acid"),
                explanation: "Exfoliant that helps unclog pores",
                status: .found(productName: "Facewash")
            )
        ],
        showEmptyState: false
    )
}

#Preview("Empty State") {
    IngredientSection(
        recommendations: [],
        showEmptyState: true
    )
}
