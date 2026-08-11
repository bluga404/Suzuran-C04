import SwiftUI

struct CategorySelector: View {
    @Binding var selectedCategory: SkincareCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(SkincareCategory.allCases) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        VStack(spacing: AppSpacing.xxs) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 24))
                                .foregroundStyle(selectedCategory == category ? .white : AppColor.accentPrimary)
                                .frame(width: 44, height: 44)
                                .background(selectedCategory == category ? AppColor.accentPrimary : AppColor.accentPrimary.opacity(0.1))
                                .clipShape(Circle())
                            
                            Text(category.displayName)
                                .font(AppTypography.caption)
                                .foregroundStyle(selectedCategory == category ? AppColor.textPrimary : AppColor.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
        }
    }
}
