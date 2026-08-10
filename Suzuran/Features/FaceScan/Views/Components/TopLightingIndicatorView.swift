import SwiftUI

/// A pill-shaped indicator displaying the current lighting condition at the top of the screen.
struct TopLightingIndicatorView: View {
    let condition: LightingCondition
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(condition.title)
                .font(.custom("AvenirNext-Bold", size: 11, relativeTo: .caption2))
                .foregroundStyle(.primary)
            
            Text(condition.subtitle)
                .font(.custom("AvenirNext-Regular", size: 10, relativeTo: .caption2))
                .foregroundStyle(.secondary)
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
