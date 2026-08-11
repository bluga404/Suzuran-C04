import SwiftUI

struct AppCard<Content: View>: View {
    var padding: CGFloat
    private let content: Content

    init(padding: CGFloat = AppSpacing.md, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                    .stroke(AppColor.borderSubtle, lineWidth: 1)
            )
    }
}
