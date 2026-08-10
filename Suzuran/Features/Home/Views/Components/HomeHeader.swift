import SwiftUI

struct HomeHeader: View {
    let date: Date
    let showCameraButton: Bool
    var onScanTap: () -> Void = {}

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Summary")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                Text(formattedDate)
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if showCameraButton {
                Button(action: onScanTap) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(12)
                        .background(Color(uiColor: .systemGray6))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Mulai pindai wajah")
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM, yyyy"
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
