import SwiftUI

/// Welcome / Splash screen (Image 1)
/// Features a centered circle placeholder and "APP NAME" text.
struct SplashView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            AppColor.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 32) {
                // Circle Placeholder
                Circle()
                    .fill(AppColor.surfacePrimary)
                    .frame(width: 180, height: 180)

                // APP NAME
                Text("Rona")
                    .font(.largeTitle)
                    .fontWeight(.bold)
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
