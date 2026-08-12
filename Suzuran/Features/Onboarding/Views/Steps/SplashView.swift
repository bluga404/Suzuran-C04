import SwiftUI

/// Welcome / Splash screen (Image 1)
/// Features a centered circle placeholder and "APP NAME" text.
struct SplashView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            Image("Splash")
                .resizable()
                .scaledToFit()
                .padding(32)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onContinue()
            }
        }
    }
}

#Preview {
    SplashView(onContinue: {})
}
