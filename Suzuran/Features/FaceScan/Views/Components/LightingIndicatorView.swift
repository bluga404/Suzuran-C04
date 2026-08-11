import SwiftUI

/// Displays contextual instruction text that updates based on the current face scan readiness state.
/// Uses a semi-transparent background with rounded corners and animates text changes.
struct LightingIndicatorView: View {
    /// The current readiness state that determines the displayed message.
    let readiness: FaceScanReadiness
    let completedAngles: Int
    let targetName: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(readiness.message)
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: readiness)
            
            Text("\(completedAngles)/3 \(targetName)")
                .font(AppTypography.caption)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: AppSpacing.md) {
            LightingIndicatorView(readiness: .searchingFace, completedAngles: 0, targetName: "Front Side")
            LightingIndicatorView(readiness: .tooFar, completedAngles: 1, targetName: "Left Side")
            LightingIndicatorView(readiness: .ready, completedAngles: 2, targetName: "Right Side")
        }
    }
}
