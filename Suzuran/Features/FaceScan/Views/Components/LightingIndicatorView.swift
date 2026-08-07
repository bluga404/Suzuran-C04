import SwiftUI

/// Displays contextual instruction text that updates based on the current face scan readiness state.
/// Uses a semi-transparent background with rounded corners and animates text changes.
struct LightingIndicatorView: View {
    /// The current readiness state that determines the displayed message.
    let readiness: FaceScanReadiness

    var body: some View {
        Text(readiness.message)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(Color.black.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.25), value: readiness)
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: AppSpacing.md) {
            LightingIndicatorView(readiness: .searchingFace)
            LightingIndicatorView(readiness: .tooFar)
            LightingIndicatorView(readiness: .ready)
        }
    }
}
