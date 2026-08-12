import SwiftUI

struct SkincareCard: View {
    let product: SkincareProduct
    let recommendationsCount: Int
    var onEdit: (() -> Void)? = nil

    var body: some View {
        AppCard {
            HStack(spacing: AppSpacing.md) {
                // Left Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .fill(AppColor.backgroundPrimary)
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                .stroke(AppColor.borderSubtle, lineWidth: 1)
                        )
                    
                    Image(systemName: product.category.iconSystemName)
                        .font(.system(size: 24))
                        .foregroundStyle(AppColor.textPrimary)
                }
                
                // Middle Texts
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(product.category.displayName)
                        .font(Font.description)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    
                    Text(product.name)
                        .font(Font.metadata)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let onEdit = onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(Font.description)
                            .foregroundStyle(AppColor.textSecondary)
                            .padding(AppSpacing.xs)
                    }
                    .buttonStyle(.borderless)
                } else if recommendationsCount > 0 {
                    Label("\(recommendationsCount) Cocok", systemImage: "sparkles")
                        .font(Font.metadata)
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
