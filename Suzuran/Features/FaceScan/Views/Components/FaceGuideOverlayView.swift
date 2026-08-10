import SwiftUI

/// An oval guide overlay indicating the target face positioning area.
/// When `isReady` is true, the oval border pulses to signal that the user's
/// face is correctly positioned and a capture is imminent.
///
/// Requirements: 4.4 — Pulsing animation on guide oval when face is ready.
struct FaceGuideOverlayView: View {
    let isReady: Bool

    @State private var isPulsing: Bool = false

    var body: some View {
        Ellipse()
            .stroke(
                isReady ? Color.green : Color.white.opacity(0.7),
                lineWidth: 3
            )
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                isReady
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .frame(width: 250, height: 340)
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
        FaceGuideOverlayView(isReady: false)
    }
}

#Preview("Ready - Pulsing") {
    ZStack {
        Color.black
        FaceGuideOverlayView(isReady: true)
    }
}
