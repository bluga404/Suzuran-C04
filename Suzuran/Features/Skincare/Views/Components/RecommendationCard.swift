import SwiftUI

/// Card that renders a single ``MatchedIngredient`` — the ingredient name, any
/// alias, the matched acne-type badges, and a truncated description.
struct RecommendationCard: View {
    let matched: MatchedIngredient
    var onTapDetail: () -> Void = {}

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(matched.recommendation.ingredientName)
                            .font(Font.description)
                            .foregroundStyle(AppColor.accentPrimary)

                        if let alternative = matched.recommendation.alternativesName {
                            Text("Alias: \(alternative)")
                                .font(Font.metadata)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        Text("Detail")
                            .font(Font.metadata)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(AppColor.accentPrimary)
                }

                // Matched Acne Types Badges
                HStack(spacing: AppSpacing.xs) {
                    Text("Matches:")
                        .font(Font.metadata)
                        .foregroundStyle(AppColor.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xxs) {
                            ForEach(matched.matchedAcneTypes) { acneType in
                                Text(acneType.displayName)
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, 2)
                                    .background(AppColor.accentPrimary.opacity(0.12))
                                    .foregroundStyle(AppColor.accentPrimary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Divider()
                    .background(AppColor.borderSubtle)

                Text(matched.recommendation.description)
                    .font(Font.metadata)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}
