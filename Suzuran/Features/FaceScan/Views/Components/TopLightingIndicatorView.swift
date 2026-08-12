import SwiftUI

/// A pill-shaped indicator displaying the current lighting condition at the top of the screen.
struct TopLightingIndicatorView: View {
    let condition: LightingCondition
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(condition.title)
                .font(Font.helperText)
                .foregroundStyle(.white)
            
            Text(condition.subtitle)
                .font(Font.system(size: 10, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
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
