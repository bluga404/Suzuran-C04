import SwiftUI

struct FaceMaskScanVisualization: View {
    let markers: [FaceMaskMarkerModel]

    var body: some View {
        AppCard {
            VStack(spacing: AppSpacing.sm) {
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height)

                    ZStack {
                        FaceMaskShape()
                            .fill(
                                RadialGradient(
                                    colors: [Color(red: 0.98, green: 0.82, blue: 0.70), Color(red: 0.73, green: 0.47, blue: 0.36)],
                                    center: .init(x: 0.42, y: 0.34),
                                    startRadius: size * 0.05,
                                    endRadius: size * 0.66
                                )
                            )
                            .overlay {
                                FaceMaskShape()
                                    .stroke(AppColor.textPrimary.opacity(0.22), lineWidth: 1.2)
                            }

                        FaceFeaturesShape()
                            .stroke(AppColor.textPrimary.opacity(0.25), lineWidth: 1)

                        ForEach(markers) { marker in
                            AcneMarker(marker: marker, canvasSize: size)
                                .position(
                                    x: size * marker.normalizedPosition.x,
                                    y: size * marker.normalizedPosition.y
                                )
                        }
                    }
                    .frame(width: size, height: size)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: 300)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Peta wajah dengan \(markers.count) jerawat terdeteksi")

                HStack(spacing: AppSpacing.sm) {
                    Circle()
                        .fill(AppColor.accentDanger)
                        .frame(width: 10, height: 10)
                    Text("Titik menunjukkan perkiraan posisi jerawat dari tiap zona scan.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct AcneMarker: View {
    let marker: FaceMaskMarkerModel
    let canvasSize: CGFloat

    private var color: Color {
        switch marker.acneType {
        case .cyst, .nodule:
            return Color(red: 0.60, green: 0.10, blue: 0.12)
        case .pustule, .papule:
            return AppColor.accentDanger
        case .blackhead:
            return AppColor.textPrimary
        case .whitehead:
            return Color(red: 0.88, green: 0.73, blue: 0.35)
        case .unknown:
            return AppColor.textSecondary
        }
    }

    var body: some View {
        let diameter = max(12, min(22, canvasSize * CGFloat(0.035 + marker.confidence * 0.025)))

        Circle()
            .fill(color.opacity(0.30))
            .overlay(Circle().stroke(color, lineWidth: 2))
            .overlay(Circle().fill(color).frame(width: diameter * 0.36, height: diameter * 0.36))
            .frame(width: diameter, height: diameter)
            .accessibilityLabel("\(marker.acneType.displayName), keyakinan \(Int(marker.confidence * 100)) persen")
    }
}

private struct FaceMaskShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()
        path.move(to: CGPoint(x: width * 0.50, y: height * 0.05))
        path.addCurve(
            to: CGPoint(x: width * 0.86, y: height * 0.39),
            control1: CGPoint(x: width * 0.74, y: height * 0.05),
            control2: CGPoint(x: width * 0.88, y: height * 0.21)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.70, y: height * 0.81),
            control1: CGPoint(x: width * 0.86, y: height * 0.60),
            control2: CGPoint(x: width * 0.76, y: height * 0.76)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.50, y: height * 0.94),
            control1: CGPoint(x: width * 0.65, y: height * 0.89),
            control2: CGPoint(x: width * 0.56, y: height * 0.94)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.30, y: height * 0.81),
            control1: CGPoint(x: width * 0.44, y: height * 0.94),
            control2: CGPoint(x: width * 0.35, y: height * 0.89)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.14, y: height * 0.39),
            control1: CGPoint(x: width * 0.24, y: height * 0.76),
            control2: CGPoint(x: width * 0.14, y: height * 0.60)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.50, y: height * 0.05),
            control1: CGPoint(x: width * 0.12, y: height * 0.21),
            control2: CGPoint(x: width * 0.26, y: height * 0.05)
        )
        return path
    }
}

private struct FaceFeaturesShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()

        path.addEllipse(in: CGRect(x: width * 0.25, y: height * 0.36, width: width * 0.18, height: height * 0.06))
        path.addEllipse(in: CGRect(x: width * 0.57, y: height * 0.36, width: width * 0.18, height: height * 0.06))
        path.move(to: CGPoint(x: width * 0.50, y: height * 0.40))
        path.addCurve(
            to: CGPoint(x: width * 0.46, y: height * 0.62),
            control1: CGPoint(x: width * 0.55, y: height * 0.50),
            control2: CGPoint(x: width * 0.50, y: height * 0.58)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.54, y: height * 0.62),
            control1: CGPoint(x: width * 0.48, y: height * 0.64),
            control2: CGPoint(x: width * 0.52, y: height * 0.64)
        )
        path.move(to: CGPoint(x: width * 0.37, y: height * 0.73))
        path.addCurve(
            to: CGPoint(x: width * 0.63, y: height * 0.73),
            control1: CGPoint(x: width * 0.45, y: height * 0.79),
            control2: CGPoint(x: width * 0.55, y: height * 0.79)
        )
        return path
    }
}

struct AcneTypeCountRow: View {
    let summary: AcneTypeSummaryModel

    var body: some View {
        AppCard {
            HStack {
                Circle()
                    .fill(markerColor)
                    .frame(width: 12, height: 12)
                Text(summary.title)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text("\(summary.count) jerawat")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private var markerColor: Color {
        switch summary.acneType {
        case .cyst, .nodule: return Color(red: 0.60, green: 0.10, blue: 0.12)
        case .pustule, .papule: return AppColor.accentDanger
        case .blackhead: return AppColor.textPrimary
        case .whitehead: return Color(red: 0.88, green: 0.73, blue: 0.35)
        case .unknown: return AppColor.textSecondary
        }
    }
}
