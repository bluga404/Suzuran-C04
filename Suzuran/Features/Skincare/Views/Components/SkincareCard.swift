import SwiftUI

struct SkincareCard: View {
    let product: SkincareProduct
    let recommendationsCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(product.name)
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColor.textPrimary)
                                .lineLimit(1)
                            
                            Text(product.brand)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Category Badge
                        Text(product.category.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 4)
                            .background(AppColor.backgroundPrimary)
                            .foregroundStyle(AppColor.textSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(AppColor.borderSubtle, lineWidth: 1)
                            )
                    }
                    
                    HStack {
                        // Current Usage Indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(product.isUsedCurrently ? AppColor.accentPrimary : AppColor.textSecondary.opacity(0.4))
                                .frame(width: 8, height: 8)
                            
                            Text(product.isUsedCurrently ? "Sedang Digunakan" : "Tidak Digunakan")
                                .font(AppTypography.caption)
                                .foregroundStyle(product.isUsedCurrently ? AppColor.accentPrimary : AppColor.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Recommendation match indicator
                        if recommendationsCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColor.accentPrimary)
                                
                                Text("\(recommendationsCount) Cocok")
                                    .font(AppTypography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColor.accentPrimary)
                            }
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 4)
                            .background(AppColor.accentPrimary.opacity(0.08))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
