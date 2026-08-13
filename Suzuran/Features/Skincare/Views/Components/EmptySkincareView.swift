import SwiftUI

/// Empty state for Skincare Home, rendered when the user has no saved products.
struct EmptySkincareView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer(minLength: AppSpacing.xl)

            ZStack {
                Circle()
                    .fill(AppColor.accentPrimary.opacity(0.05))
                    .frame(width: 100, height: 100)

                Image(systemName: "bubbles.and.sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColor.accentPrimary)
            }

            Text(SkincareStrings.emptyTitle)
                .font(Font.bodyParagraph)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)

            Text(SkincareStrings.emptyMessage)
                .font(Font.metadata)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)

            Button(action: onAdd) {
                Text(SkincareStrings.addFirstProduct)
                    .font(Font.description)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColor.accentPrimary)
                    .foregroundStyle(AppColor.textOnAccent)
                    .cornerRadius(AppCornerRadius.md)
            }
            .padding(.top, AppSpacing.sm)
            .accessibilityLabel(Text(SkincareStrings.addSkincare))

            Spacer(minLength: AppSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }
}

#Preview {
    EmptySkincareView(onAdd: {})
        .background(AppColor.backgroundPrimary)
}
