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
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Ingredients")
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
                    Text("Scan your skincare products to see which ones may suit your skin condition.")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(visibleRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                        IngredientRecommendationCard(recommendation: recommendation)
                        if index < visibleRecommendations.count - 1 {
                            Divider()
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
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surfacePrimary)
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
