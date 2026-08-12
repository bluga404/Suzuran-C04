import SwiftUI

/// Displays the ingredient recommendations as a single card consistent with
/// the Skin Condition and Most Detected sections.
struct IngredientSection: View {
    let recommendations: [IngredientRecommendation]
    let hasTrackedSkincare: Bool
    var onTrackTap: () -> Void = {}
    var onIngredientTap: (IngredientRecommendation) -> Void = { _ in }

    private var visibleRecommendations: [IngredientRecommendation] {
        Array(recommendations.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Standalone Section Title (Font.bodyLarge)
            Text("Recommended Ingredients")
                .font(Font.bodyLarge)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.md)

            if visibleRecommendations.isEmpty {
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        if hasTrackedSkincare {
                            Text("Here, you'll find ingredients that may help with your most common acne type.")
                                .font(Font.description)
                                .italic()
                                .foregroundStyle(AppColor.textSecondary)
                        } else {
                            Text("Here, you'll find ingredients that may help with your most common acne type. Add your skincare routine to see if your products already contain them.")
                                .font(Font.description)
                                .italic()
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            } else {
                // Stack of individual recommendation cards
                VStack(spacing: AppSpacing.sm) {
                    ForEach(visibleRecommendations) { recommendation in
                        Button(action: { onIngredientTap(recommendation) }) {
                            IngredientRecommendationCard(
                                recommendation: recommendation,
                                hasTrackedSkincare: hasTrackedSkincare
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                if !hasTrackedSkincare {
                    tipsBox
                        .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }

    private var tipsBox: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                // Lightbulb icon in circular white container
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                    Image(systemName: "lightbulb")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColor.surfacePurple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Tips for better insight")
                        .font(Font.metadata)
                        .foregroundStyle(AppColor.surfacePurple)

                    Text("Add your skincare routine to see if your products already contain them.")
                        .font(Font.metadata)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            trackButton
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfaceTipsBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
    }

    private var trackButton: some View {
        Button(action: onTrackTap) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "plus")
                    .font(Font.label)
                Text("Add New Skincare")
                    .font(Font.label)
            }
            .foregroundStyle(AppColor.surfacePurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .stroke(AppColor.surfacePurple, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("With Recommendations (No Skincare)") {
    IngredientSection(
        recommendations: [
            IngredientRecommendation(
                id: UUID(),
                ingredient: Ingredient(name: "niacinamide", displayName: "Niacinamide"),
                detail: SkincareIngredientRecommendation(
                    ingredientName: "Niacinamide",
                    alternativesName: nil,
                    acneTypes: "Papule, Pustule",
                    description: "Excellent for penetrating pores to dissolve sebum and dead skin cells, helping to clear breakouts.",
                    concentrationAndUsage: "", application: "", ingredientInteractions: nil, risksAndSafety: "", researchPapers: nil
                ),
                status: .notFound
            )
        ],
        hasTrackedSkincare: false
    )
}

#Preview("With Recommendations (With Skincare)") {
    IngredientSection(
        recommendations: [
            IngredientRecommendation(
                id: UUID(),
                ingredient: Ingredient(name: "niacinamide", displayName: "Niacinamide"),
                detail: SkincareIngredientRecommendation(
                    ingredientName: "Niacinamide",
                    alternativesName: nil,
                    acneTypes: "Papule, Pustule",
                    description: "Excellent for penetrating pores to dissolve sebum and dead skin cells, helping to clear breakouts.",
                    concentrationAndUsage: "", application: "", ingredientInteractions: nil, risksAndSafety: "", researchPapers: nil
                ),
                status: .notFound
            )
        ],
        hasTrackedSkincare: true
    )
}

#Preview("Empty State") {
    IngredientSection(
        recommendations: [],
        hasTrackedSkincare: false
    )
}
