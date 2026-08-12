import SwiftUI

struct IngredientRecommendationCard: View {
    let recommendation: IngredientRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(recommendation.ingredient.displayName)
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)

                Text(recommendation.explanation)
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineSpacing(2)
            }

            statusPill
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .stroke(AppColor.surfacePurple, lineWidth: 2)
        )
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
            .font(Font.metadata)
            .foregroundStyle(AppColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColor.borderSubtle.opacity(0.5))
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
