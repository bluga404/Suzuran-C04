import SwiftUI

/// A pill-shaped indicator displaying the current lighting condition at the top of the screen.
struct TopLightingIndicatorView: View {
    let condition: LightingCondition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(condition.title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black)
            
            Text(condition.subtitle)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.black.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            // Use a solid grey color matching the design image with some opacity
            Capsule()
                .fill(Color(white: 0.6).opacity(0.85))
        )
        // Transition to slide or fade when appearing
        .animation(.easeInOut(duration: 0.3), value: condition)
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        VStack(spacing: 20) {
            TopLightingIndicatorView(condition: .good)
            TopLightingIndicatorView(condition: .tooDark)
            TopLightingIndicatorView(condition: .tooBright)
        }
    }
}
