import SwiftUI

struct AppCard<Content: View>: View {
    var padding: CGFloat
    var backgroundColor: Color
    var borderColor: Color
    private let content: Content

    init(
        padding: CGFloat = AppSpacing.md,
        backgroundColor: Color = AppColor.surfacePrimary,
        borderColor: Color = AppColor.borderSubtle,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}
