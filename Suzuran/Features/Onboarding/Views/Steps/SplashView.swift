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
                Text("APP NAME")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColor.textPrimary)
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
