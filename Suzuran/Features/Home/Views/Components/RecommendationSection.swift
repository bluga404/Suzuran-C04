import SwiftUI

struct RecommendationSection: View {
    let recommendations: [IngredientRecommendation]
    let showEmptyState: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Rekomendasi Bahan")
                .font(AppTypography.bodyBold)
                .foregroundStyle(.primary)
                .padding(.horizontal, AppSpacing.md)

            if recommendations.isEmpty && showEmptyState {
                Text("Scan produk skincaremu untuk melihat rekomendasi bahan")
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppSpacing.md)
            } else {
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
