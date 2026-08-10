import SwiftUI

struct TrackSkincareButton: View {
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            Text("Track your Skincare")
                .font(AppTypography.bodyBold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.black)
                .clipShape(Capsule())
        }
        .padding(.horizontal, AppSpacing.md)
        .accessibilityLabel("Track skincare products")
    }
}
