import SwiftUI

/// Card that renders a single ``MatchedIngredient`` — the ingredient name, any
/// alias, the matched acne-type badges, and a truncated description.
///
/// away from the removed `MatchedRecommendation`). The optional `onTapDetail`
/// affordance drives the inline "Detail" button; when the whole card is already
/// wrapped in a `Button` (see ``MatchedIngredientSection``) callers can omit it.
///
struct RecommendationCard: View {
    let matched: MatchedIngredient
    var isCompact: Bool = false

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(matched.recommendation.ingredientName)
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColor.accentPrimary)

                        if let alternative = matched.recommendation.alternativesName {
                            Text("Alias: \(alternative)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }

                    Spacer()

                    if !isCompact {
                        HStack(spacing: 2) {
                            Text("Detail")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(AppColor.accentPrimary)
                    }
                }

                // Matched Acne Types Badges
                HStack(spacing: AppSpacing.xs) {
                    Text("Cocok untuk:")
                        .font(AppTypography.caption)
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

                if !isCompact {
                    Divider()
                        .background(AppColor.borderSubtle)

                    Text(matched.recommendation.description)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
}
