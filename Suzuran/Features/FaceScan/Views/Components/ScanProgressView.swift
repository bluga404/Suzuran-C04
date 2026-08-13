import SwiftUI

/// Displays a circular progress ring that fills as the hold-to-capture countdown progresses,
/// along with a zone progress indicator showing completed angles (e.g., 1/3, 2/3, 3/3).
struct ScanProgressView: View {
    /// Hold progress value from 0.0 (not started) to 1.0 (capture triggered).
    let holdProgress: Double
    /// Number of angles completed so far (0, 1, 2, or 3).
    let completedAngles: Int

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                // Background track ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)

                // Active progress ring
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        AppColor.accentPrimary,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: holdProgress)
            }

            // Zone progress indicator
            Text("\(completedAngles)/3")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, AppSpacing.xxs)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())
        }
    }
}

#Preview {
    ZStack {
        Color.black
        ScanProgressView(holdProgress: 0.6, completedAngles: 1)
            .frame(width: 200, height: 240)
    }
}
