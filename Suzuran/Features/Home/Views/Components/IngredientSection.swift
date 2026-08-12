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
        AppCard(padding: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Text("Recommended Ingredients")
                        .font(Font.metadata)
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                if visibleRecommendations.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        if hasTrackedSkincare {
                            Text("Here, you'll find ingredients that may help with your most common acne type.")
                                .font(Font.description)
                                .italic()
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Here, you'll find ingredients that may help with your most common acne type. Add your skincare routine to see if your products already contain them.")
                                .font(Font.description)
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(Array(visibleRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                            Button(action: { onIngredientTap(recommendation) }) {
                                IngredientRecommendationCard(
                                    recommendation: recommendation,
                                    hasTrackedSkincare: hasTrackedSkincare
                                )
                            }
                            .buttonStyle(.plain)
                            
                            if index < visibleRecommendations.count - 1 {
                                Divider()
                            }
                        }
                    }
                    
                    if !hasTrackedSkincare {
                        tipsBox
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
    
    private var tipsBox: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AppColor.surfacePurple)
                Text("Tips for better insight")
                    .font(Font.description.weight(.bold))
                    .foregroundStyle(AppColor.surfacePurple)
            }
            Text("Add your skincare routine to see if your products already contain them.")
                .font(Font.metadata)
                .foregroundStyle(AppColor.textSecondary)
            
            trackButton
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePurple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
    }
    
    private var trackButton: some View {
        Button(action: onTrackTap) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "plus")
                Text("Add New Skincare")
                    .font(Font.metadata.weight(.semibold))
            }
            .foregroundStyle(AppColor.surfacePurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .stroke(AppColor.surfacePurple, lineWidth: 1)
            )
        }
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
