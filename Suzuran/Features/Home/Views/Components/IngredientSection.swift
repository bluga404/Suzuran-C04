import SwiftUI

/// Displays the ingredient recommendations as a single card consistent with
/// the Skin Condition and Most Detected sections: an "INGREDIENTS" header with
/// an info button, followed by ingredient rows (or a placeholder when no data).
struct IngredientSection: View {
    let recommendations: [IngredientRecommendation]
    let showEmptyState: Bool
    var onTrackTap: () -> Void = {}

    private var visibleRecommendations: [IngredientRecommendation] {
        Array(recommendations.prefix(5))
    }
    var body: some View {
        if visibleRecommendations.isEmpty && showEmptyState {
            AppCard(padding: AppSpacing.lg, backgroundColor: AppColor.surfacePurple, borderColor: .clear) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Ingredients")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                    
                    Text("Scan your skincare products to get ingredients recommendations")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textPrimary)
                    
                    Button(action: onTrackTap) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "plus")
                            Text("Track your Skincare")
                                .font(AppTypography.bodyBold)
                        }
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(AppColor.buttonPrimaryPurple)
                        .clipShape(Capsule())
                    }
                    .padding(.top, AppSpacing.xs)
                }
            }
            .padding(.horizontal, AppSpacing.md)
        } else if !visibleRecommendations.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Recommended Ingredients")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.horizontal, AppSpacing.md)
                
                VStack(spacing: 12) {
                    ForEach(Array(visibleRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                        IngredientRecommendationCard(recommendation: recommendation)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
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
