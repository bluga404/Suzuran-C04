import SwiftUI

/// Welcome / Splash screen (Image 1)
/// Features a centered circle placeholder and "APP NAME" text.
struct SplashView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                Image("Splash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)

                Text("RONA")
                    .font(Font.system(size: 26, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(AppColor.textPrimary)
            }
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
