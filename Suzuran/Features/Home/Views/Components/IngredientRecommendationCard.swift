import SwiftUI

struct IngredientRecommendationCard: View {
    let recommendation: IngredientRecommendation
    let hasTrackedSkincare: Bool

    var body: some View {
        AppCard(backgroundColor: AppColor.surfacePrimary, borderColor: AppColor.borderSubtle) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(alignment: .center) {
                    Text(recommendation.ingredient.displayName)
                        .font(Font.sectionTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Font.bodyLarge)
                        .foregroundStyle(AppColor.textPrimary)
                }

                Text(recommendation.detail.description)
                    .font(Font.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .lineSpacing(2)

                if hasTrackedSkincare {
                    Divider()
                        .padding(.vertical, AppSpacing.xs)
                    statusSection
                }
            }
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
        }
        .frame(minHeight: 122)
    }

    @ViewBuilder
    private var statusSection: some View {
        switch recommendation.status {
        case .notFound:
            Text("None of your skincare contains this ingredients")
                .font(Font.metadata.italic())
                .foregroundStyle(AppColor.textSecondary)
        case .found(let products):
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Your skincare with this ingredients:")
                    .font(Font.metadata)
                    .foregroundStyle(AppColor.textPrimary)
                
                ForEach(products, id: \.id) { product in
                    HStack(spacing: AppSpacing.xs) {
                        Text(product.name)
                            .font(Font.metadata)
                            .foregroundStyle(AppColor.textPrimary)
                        
                        Text(product.category.displayName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppColor.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColor.surfacePurple)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

#Preview("Not Found with Skincare") {
    IngredientRecommendationCard(
        recommendation: IngredientRecommendation(
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
        ),
        hasTrackedSkincare: true
    )
}

#Preview("Found with Skincare") {
    IngredientRecommendationCard(
        recommendation: IngredientRecommendation(
            id: UUID(),
            ingredient: Ingredient(name: "salicylic acid", displayName: "Salicylic Acid"),
            detail: SkincareIngredientRecommendation(
                ingredientName: "Salicylic Acid",
                alternativesName: nil,
                acneTypes: "Blackhead, Whitehead",
                description: "A beta hydroxy acid that exfoliates the skin and keeps pores clear.",
                concentrationAndUsage: "", application: "", ingredientInteractions: nil, risksAndSafety: "", researchPapers: nil
            ),
            status: .found(products: [
                SkincareProduct(name: "Wardah Lightening Gentle Wash", brand: "Wardah", category: .cleanser)
            ])
        ),
        hasTrackedSkincare: true
    )
}

#Preview("No Skincare") {
    IngredientRecommendationCard(
        recommendation: IngredientRecommendation(
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
        ),
        hasTrackedSkincare: false
    )
}
