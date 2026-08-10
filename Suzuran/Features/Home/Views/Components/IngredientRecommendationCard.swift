import SwiftUI

struct IngredientRecommendationCard: View {
    let recommendation: IngredientRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(recommendation.ingredient.displayName)
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColor.textPrimary)

            Text(recommendation.explanation)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)

            statusPill
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        .padding(.horizontal, AppSpacing.md)
    }

    @ViewBuilder
    private var statusPill: some View {
        let text: String = {
            switch recommendation.status {
            case .notFound:
                return "Belum ditemukan di produk yang kamu scan"
            case .found(let productName):
                return "Sudah ada di rutinmu - \(productName)"
            }
        }()

        Text(text)
            .font(AppTypography.caption)
            .foregroundStyle(AppColor.textSecondary)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
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
