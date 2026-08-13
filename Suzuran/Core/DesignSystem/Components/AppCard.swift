import SwiftUI

struct AppCard<Content: View>: View {
    var backgroundColor: Color
    var borderColor: Color
    var borderWidth: CGFloat
    var cornerRadius: CGFloat
    private let content: Content

    init(
        backgroundColor: Color = AppColor.surfacePrimary,
        borderColor: Color = AppColor.borderSubtle,
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = AppCornerRadius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
}
