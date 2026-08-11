import SwiftUI

struct RecommendationCard: View {
    let match: MatchedRecommendation
    let onTapDetail: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(match.recommendation.ingredientName)
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColor.accentPrimary)
                        
                        if let alternative = match.recommendation.alternativesName {
                            Text("Alias: \(alternative)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onTapDetail) {
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
                            ForEach(match.matchedAcneTypes) { acneType in
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
                
                Text(match.recommendation.description)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}
