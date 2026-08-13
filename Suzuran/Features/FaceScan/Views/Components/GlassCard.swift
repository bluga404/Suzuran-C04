import SwiftUI

/// A reusable card component for the face scan result screen.
/// Uses a rounded rectangle with material background for a clean, modern look.
struct GlassCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .fill(.regularMaterial)
            )
    }
}
