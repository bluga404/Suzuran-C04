import SwiftUI

struct HomeHeader: View {
    let date: Date
    let showCameraButton: Bool
    var onScanTap: () -> Void = {}

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Summary")
                    .font(AppTypography.title)
                    .foregroundStyle(.primary)
                Text(formattedDate)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if showCameraButton {
                Button(action: onScanTap) {
                    Image(systemName: "camera")
                        .font(.title2)
                        .foregroundStyle(AppColor.accentPrimary)
                }
                .accessibilityLabel("Start face scan")
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview("With Camera Button") {
    HomeHeader(
        date: Date(),
        showCameraButton: true,
        onScanTap: {}
    )
}

#Preview("Without Camera Button") {
    HomeHeader(
        date: Date(),
        showCameraButton: false
    )
}
