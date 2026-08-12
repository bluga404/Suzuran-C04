import SwiftUI

/// Empty state for Skincare Home, rendered when the user has no saved products.
///
/// Mirrors mockup `00_EmptyState.png`: an illustrative SF Symbol, a title, an
/// explanatory body, and a primary "Tambah Skincare" call-to-action. Purely
/// presentational — the parent (``SkincareView``) supplies the `onAdd` closure
/// which opens the Add flow.
///
/// Uses design tokens (`AppSpacing`, `AppColor`, `AppTypography`) exclusively —
/// no hardcoded colors or sizes (Req 9.5, 24.1).
///
struct EmptySkincareView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer(minLength: AppSpacing.xl)

            ZStack {
                Circle()
                    .fill(AppColor.buttonPrimaryPurple.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "bubbles.and.sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColor.buttonPrimaryPurple)
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
                    .background(AppColor.buttonPrimaryPurple)
                    .foregroundStyle(Color.white)
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
