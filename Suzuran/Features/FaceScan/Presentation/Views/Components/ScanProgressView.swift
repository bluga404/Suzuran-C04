import SwiftUI

struct ScanProgressView: View {
    let completedZones: [FaceZone]
    let currentZone: FaceZone?
    let holdProgress: Double  // 0.0 – 1.0

    /// Only these 5 zones are scanned in the face scan flow
    private let scanZones: [FaceZone] = [.forehead, .nose, .chin, .rightCheek, .leftCheek]

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(scanZones, id: \.self) { zone in
                let isCompleted = completedZones.contains(zone)
                let isCurrent = currentZone == zone

                VStack(spacing: 4) {
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(
                                isCompleted ? AppColor.accentPrimary :
                                Color.gray.opacity(0.4)
                            )
                            .frame(width: 18, height: 18)

                        // Hold progress ring (only for current zone)
                        if isCurrent && !isCompleted {
                            Circle()
                                .trim(from: 0, to: holdProgress)
                                .stroke(AppColor.accentPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 22, height: 22)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: holdProgress)
                        }

                        // Checkmark for completed zones
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                    }

                    Text(zone.displayName)
                        .font(.system(size: 10, weight: isCurrent ? .bold : .regular))
                        .foregroundStyle(
                            isCompleted ? AppColor.accentPrimary :
                            (isCurrent ? Color.white : Color.white.opacity(0.6))
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .fill(Color.black.opacity(0.6))
        )
    }
}
