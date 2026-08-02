import SwiftUI

struct ScreenContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.backgroundPrimary)
    }
}

extension View {
    func appScreenContainer() -> some View {
        modifier(ScreenContainerModifier())
    }
}
