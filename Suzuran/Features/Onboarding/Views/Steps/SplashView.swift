import SwiftUI

/// Welcome / Splash screen (Image 1)
/// Features a centered circle placeholder and "APP NAME" text.
struct SplashView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 32) {
                // Circle Placeholder
                Circle()
                    .fill(Color(white: 0.8))
                    .frame(width: 180, height: 180)

                // APP NAME
                Text("APP NAME")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onContinue()
        }
    }
}

#Preview {
    SplashView(onContinue: {})
}
