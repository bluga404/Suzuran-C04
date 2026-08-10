import SwiftUI

struct RecommendationSection: View {
    let recommendations: [IngredientRecommendation]
    let showEmptyState: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if recommendations.isEmpty && showEmptyState {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Scan to get recommendations")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(.primary)
                    Text("Scan your face to see ingredients that may suit your skin condition.")
                        .font(AppTypography.body)
                        .italic()
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, AppSpacing.md)
            } else {
                Text("Recommended Ingredients")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, AppSpacing.md)

                ForEach(recommendations.prefix(5)) { recommendation in
                    IngredientRecommendationCard(recommendation: recommendation)
                }
            }
        }
    }
}

#Preview("With Recommendations") {
    RecommendationSection(
        recommendations: [
            IngredientRecommendation(
                id: UUID(),
                ingredient: Ingredient(name: "niacinamide", displayName: "Niacinamide"),
                explanation: "Membantu mengontrol produksi sebum",
                status: .notFound
            ),
            IngredientRecommendation(
                id: UUID(),
                ingredient: Ingredient(name: "salicylic acid", displayName: "Salicylic Acid"),
                explanation: "Exfoliant yang membantu membersihkan pori-pori",
                status: .found(productName: "Facewash")
            )
        ],
        showEmptyState: false
    )
}

#Preview("Empty State") {
    RecommendationSection(
        recommendations: [],
        showEmptyState: true
    )
}
