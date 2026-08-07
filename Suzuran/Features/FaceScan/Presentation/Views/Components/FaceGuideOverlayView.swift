import SwiftUI

struct FaceGuideOverlayView: View {
    let isFaceInPosition: Bool
    let proximity: FaceProximity
    let holdProgress: Double  // 0.0 – 1.0
    let readiness: FaceScanReadiness
    let instruction: String

    var body: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.size.width
            let frameHeight = geometry.size.height
            let ovalWidth = frameWidth * 0.85
            let ovalHeight = frameHeight * 0.60

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

                // Guidance Text Banner — positioned ABOVE the oval
                VStack {
                    Spacer()
                        .frame(height: max(0, (frameHeight - ovalHeight) / 2 - 60))

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

                    Spacer()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
