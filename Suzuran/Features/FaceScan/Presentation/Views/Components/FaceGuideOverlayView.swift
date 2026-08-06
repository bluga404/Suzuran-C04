import SwiftUI

struct FaceGuideOverlayView: View {
    let isFaceInPosition: Bool
    let currentZone: FaceZone?
    let holdProgress: Double  // 0.0 – 1.0
    let readiness: FaceScanReadiness
    let targetZones: [FaceZone]
    let instruction: String

    var body: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.size.width
            let frameHeight = geometry.size.height
            let ovalWidth = frameWidth * 0.72
            let ovalHeight = frameHeight * 0.48

            ZStack {
                // Dimmed background with oval cutout
                Rectangle()
                    .fill(Color.black.opacity(0.45))
                    .mask(
                        Rectangle()
                            .overlay(
                                Ellipse()
                                    .frame(width: ovalWidth, height: ovalHeight)
                                    .blendMode(.destinationOut)
                            )
                    )

                // Hold progress ring around the oval
                if holdProgress > 0 {
                    Ellipse()
                        .trim(from: 0, to: holdProgress)
                        .stroke(AppColor.accentPrimary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: ovalWidth + 6, height: ovalHeight + 6)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: holdProgress)
                }

                // Oval Focus Box Border
                Ellipse()
                    .stroke(
                        isFaceInPosition ? AppColor.accentPrimary.opacity(0.8) : Color.white.opacity(0.6),
                        style: StrokeStyle(lineWidth: isFaceInPosition ? 3 : 2, dash: isFaceInPosition ? [] : [10, 8])
                    )
                    .frame(width: ovalWidth, height: ovalHeight)

                ForEach(targetZones, id: \.self) { zone in
                    FaceZoneMask(zone: zone)
                        .fill(AppColor.accentPrimary.opacity(0.28))
                        .overlay {
                            FaceZoneMask(zone: zone)
                                .stroke(AppColor.accentPrimary, lineWidth: 2)
                        }
                        .frame(width: ovalWidth, height: ovalHeight)
                        .allowsHitTesting(false)
                }

                // Guidance Text Banner — positioned ABOVE the oval
                VStack {
                    Spacer()
                        .frame(height: max(0, (frameHeight - ovalHeight) / 2 - 60))

                    if currentZone != nil {
                        VStack(spacing: 4) {
                            Text(instruction)
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(Color.white)
                                .multilineTextAlignment(.center)

                            if holdProgress > 0 && readiness.allowsCapture {
                                Text("Tahan posisi...")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.accentPrimary)
                            } else {
                                Text(readiness.message)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(readiness.allowsCapture ? Color.green : Color.white.opacity(0.85))
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                .fill(Color.black.opacity(0.7))
                        )
                    }

                    Spacer()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

private struct FaceZoneMask: Shape {
    let zone: FaceZone

    func path(in rect: CGRect) -> Path {
        let zoneRect: CGRect
        switch zone {
        case .forehead:
            zoneRect = CGRect(x: rect.width * 0.28, y: rect.height * 0.12, width: rect.width * 0.44, height: rect.height * 0.22)
        case .rightCheek:
            zoneRect = CGRect(x: rect.width * 0.12, y: rect.height * 0.38, width: rect.width * 0.30, height: rect.height * 0.30)
        case .leftCheek:
            zoneRect = CGRect(x: rect.width * 0.58, y: rect.height * 0.38, width: rect.width * 0.30, height: rect.height * 0.30)
        case .nose:
            zoneRect = CGRect(x: rect.width * 0.42, y: rect.height * 0.34, width: rect.width * 0.16, height: rect.height * 0.32)
        case .chin:
            zoneRect = CGRect(x: rect.width * 0.34, y: rect.height * 0.70, width: rect.width * 0.32, height: rect.height * 0.16)
        case .jawline:
            zoneRect = CGRect(x: rect.width * 0.18, y: rect.height * 0.66, width: rect.width * 0.64, height: rect.height * 0.20)
        }
        return Path(ellipseIn: zoneRect)
    }
}
