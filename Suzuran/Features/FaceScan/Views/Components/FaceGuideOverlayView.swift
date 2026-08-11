import SwiftUI

/// An oval guide overlay indicating the target face positioning area.
/// When `isReady` is true, the oval border pulses to signal that the user's
/// face is correctly positioned and a capture is imminent.
///
/// Requirements: 4.4 — Pulsing animation on guide oval when face is ready.
struct FaceGuideOverlayView: View {
    let isReady: Bool
    let holdProgress: Double
    let completedAngles: Int

    @State private var isPulsing: Bool = false

    var body: some View {
        ZStack {
            // Unified Guide & Progress Ring
            ZStack {
                // Base transparent track (acts as the face guide)
                Ellipse()
                    .stroke(
                        Color.gray.opacity(0.8),
                        style: StrokeStyle(lineWidth: 8, dash: [12, 12])
                    )

                // Active progress fill (fills up the track)
                Ellipse()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        AppColor.accentPrimary,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
            }
            .frame(width: 440, height: 320) // Swapped dimensions
            .rotationEffect(.degrees(-90))
            .scaleEffect(isPulsing ? 1.03 : 1.0) // Pulse them together
            .animation(
                isReady
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .animation(.linear(duration: 0.1), value: holdProgress)
        }
        .frame(width: 320, height: 440)
        .onChange(of: isReady) { _, newValue in
            isPulsing = newValue
        }
        .onAppear {
            isPulsing = isReady
        }
    }
}

#Preview("Not Ready") {
    ZStack {
        Color.black
        FaceGuideOverlayView(isReady: false, holdProgress: 0.3, completedAngles: 1)
    }
}

#Preview("Ready - Pulsing") {
    ZStack {
        Color.black
        FaceGuideOverlayView(isReady: true, holdProgress: 1.0, completedAngles: 3)
    }
}
