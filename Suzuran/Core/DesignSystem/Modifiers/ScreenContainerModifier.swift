import SwiftUI

struct ScreenContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
    }
}

extension View {
    func appScreenContainer() -> some View {
        modifier(ScreenContainerModifier())
    }
}
