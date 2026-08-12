import SwiftUI

struct GeneralRecommendationCard: View {
    let display: SkincareViewModel.RecommendedIngredientDisplay
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(display.recommendation.ingredientName)
                    .font(.title3.bold())
                    .foregroundStyle(AppColor.textPrimary)
                
                Text(display.recommendation.description)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Status Badge
                HStack {
                    switch display.status {
                    case .notFound:
                        Text("Not found in your scanned product")
                            .font(AppTypography.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 6)
                            .background(AppColor.accentPrimary.opacity(0.12))
                            .foregroundStyle(AppColor.accentPrimary)
                            .clipShape(Capsule())
                    case .found(let category):
                        Text("Already in your routine - \(category)")
                            .font(AppTypography.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 6)
                            .background(AppColor.accentPrimary.opacity(0.12))
                            .foregroundStyle(AppColor.accentPrimary)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 4)
            }
        }
        // Apply stroke to match the design (light purple outline)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .stroke(AppColor.accentPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}
