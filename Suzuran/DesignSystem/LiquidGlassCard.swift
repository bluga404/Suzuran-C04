import SwiftUI

struct LiquidGlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Theme.glassStroke, lineWidth: 1.5)
            )
            .overlay(
                // Inner highlight for 3D liquid feel
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .blur(radius: 2)
                    .offset(x: 2, y: 2)
                    .mask(RoundedRectangle(cornerRadius: 24))
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}
