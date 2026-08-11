import SwiftUI

struct SkincareCard: View {
    let product: SkincareProduct
    let recommendationsCount: Int
    var onEdit: (() -> Void)? = nil

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
                    
                    Image(systemName: product.category.iconSystemName)
                        .font(.system(size: 24))
                        .foregroundStyle(AppColor.textPrimary)
                }
                
                // Middle Texts
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(product.category.displayName)
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    
                    Text(product.name)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let onEdit = onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                            .padding(AppSpacing.xs)
                    }
                    .buttonStyle(.borderless)
                } else if recommendationsCount > 0 {
                    Label("\(recommendationsCount) Cocok", systemImage: "sparkles")
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.accentPrimary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppColor.accentPrimary.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
