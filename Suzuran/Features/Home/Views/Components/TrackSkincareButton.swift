import SwiftUI

struct TrackSkincareButton: View {
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            Text("Track your Skincare")
                .font(AppTypography.bodyBold)
                .foregroundStyle(Color(uiColor: .systemBackground))
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, AppSpacing.sm)
                .background(Color.primary)
                .clipShape(Capsule())
        }
        .padding(.horizontal, AppSpacing.md)
        .accessibilityLabel("Track skincare products")
    }
}
