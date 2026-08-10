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
                    .font(AppTypography.subtitle)
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
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xxs)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
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
