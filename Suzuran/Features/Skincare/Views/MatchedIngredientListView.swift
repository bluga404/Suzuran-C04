import SwiftUI

/// Full aggregate match list reached from Home's "Lihat Semua" preview action.
/// Uses a standard navigation push to ingredient detail, matching the 08 → 09 →
/// 10 flow in the visual references.
struct MatchedIngredientListView: View {
    let matched: [MatchedIngredient]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(matched) { item in
                    NavigationLink {
                        IngredientDetailView(
                            recommendation: item.recommendation,
                            showsCloseButton: false
                        )
                    } label: {
                        RecommendationCard(matched: item)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("\(item.recommendation.ingredientName), lihat detail"))
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary)
        .navigationTitle("Ingredient yang Cocok")
        .navigationBarTitleDisplayMode(.inline)
    }
}
