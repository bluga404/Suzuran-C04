import SwiftUI

struct IngredientRecommendationCard: View {
    let recommendation: IngredientRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(recommendation.ingredient.displayName)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.textPrimary)

                Text(recommendation.explanation)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
            }

            statusPill
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
        .padding(.horizontal, AppSpacing.md)
    }

    @ViewBuilder
    private var statusPill: some View {
        let text: String = {
            switch recommendation.status {
            case .notFound:
                return "Not found in your scanned product"
            case .found(let productName):
                return "Already in your routine - \(productName)"
            }
        }()

        Text(text)
            .font(.system(size: 13, weight: .regular, design: .default))
            .foregroundStyle(AppColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(uiColor: .systemGray4))
            .clipShape(Capsule())
    }
}

#Preview("Not Found") {
    IngredientRecommendationCard(
        recommendation: IngredientRecommendation(
            id: UUID(),
            ingredient: Ingredient(name: "niacinamide", displayName: "Niacinamide"),
            explanation: "Membantu mengontrol produksi sebum dan memperbaiki skin barrier",
            status: .notFound
        )
    )
}

#Preview("Found") {
    IngredientRecommendationCard(
        recommendation: IngredientRecommendation(
            id: UUID(),
            ingredient: Ingredient(name: "salicylic acid", displayName: "Salicylic Acid"),
            explanation: "Exfoliant yang membantu membersihkan pori-pori tersumbat",
            status: .found(productName: "Facewash")
        )
    )
}
