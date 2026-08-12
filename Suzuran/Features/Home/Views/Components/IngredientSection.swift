import SwiftUI

/// Displays the ingredient recommendations as a single card consistent with
/// the Skin Condition and Most Detected sections: an "INGREDIENTS" header with
/// an info button, followed by ingredient rows (or a placeholder when no data).
struct IngredientSection: View {
    let recommendations: [IngredientRecommendation]
    let showEmptyState: Bool
    var onInfoTap: () -> Void = {}
    var onTrackTap: () -> Void = {}

    private var visibleRecommendations: [IngredientRecommendation] {
        Array(recommendations.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section Header
            Text("Recommended Ingredients")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppColor.textPrimary)

            if visibleRecommendations.isEmpty && showEmptyState {
                Text("Scan your skincare products to get ingredient recommendations")
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(visibleRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                        IngredientRecommendationCard(recommendation: recommendation)
                    }
                }
            }
            
            Button(action: onTrackTap) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text("Track Your Skincare")
                        .font(AppTypography.bodyBold)
                }
                .foregroundStyle(Color(uiColor: .systemBackground))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.primary)
                .clipShape(Capsule())
            }
            .padding(.top, AppSpacing.xs)
            .accessibilityLabel("Track skincare products")
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
