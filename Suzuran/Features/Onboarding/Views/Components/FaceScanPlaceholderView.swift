import SwiftUI

/// Vector placeholder view representing the Face Scan brackets `[ 👤 ]`
/// rendered entirely using SwiftUI shapes without external assets.
struct FaceScanPlaceholderView: View {
    var size: CGFloat = 220
    var color: Color = Color(white: 0.8)

    var body: some View {
        ZStack {
            // 1. Bracket Corners
            bracketCorners

            // 2. Person Head & Shoulder Silhouette
            personSilhouette
        }
        .frame(width: size, height: size)
    }

    // MARK: - Bracket Corners

    private var bracketCorners: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cornerLength = w * 0.28
            let radius: CGFloat = 24
            let lineCap = StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)

            // Top-Left Corner
            var tl = Path()
            tl.move(to: CGPoint(x: 0, y: cornerLength))
            tl.addLine(to: CGPoint(x: 0, y: radius))
            tl.addQuadCurve(to: CGPoint(x: radius, y: 0), control: CGPoint(x: 0, y: 0))
            tl.addLine(to: CGPoint(x: cornerLength, y: 0))
            context.stroke(tl, with: .color(color), style: lineCap)

            // Top-Right Corner
            var tr = Path()
            tr.move(to: CGPoint(x: w - cornerLength, y: 0))
            tr.addLine(to: CGPoint(x: w - radius, y: 0))
            tr.addQuadCurve(to: CGPoint(x: w, y: radius), control: CGPoint(x: w, y: 0))
            tr.addLine(to: CGPoint(x: w, y: cornerLength))
            context.stroke(tr, with: .color(color), style: lineCap)

            // Bottom-Left Corner
            var bl = Path()
            bl.move(to: CGPoint(x: 0, y: h - cornerLength))
            bl.addLine(to: CGPoint(x: 0, y: h - radius))
            bl.addQuadCurve(to: CGPoint(x: radius, y: h), control: CGPoint(x: 0, y: h))
            bl.addLine(to: CGPoint(x: cornerLength, y: h))
            context.stroke(bl, with: .color(color), style: lineCap)

            // Bottom-Right Corner
            var br = Path()
            br.move(to: CGPoint(x: w - cornerLength, y: h))
            br.addLine(to: CGPoint(x: w - radius, y: h))
            br.addQuadCurve(to: CGPoint(x: w, y: radius), control: CGPoint(x: w, y: h))
            br.addLine(to: CGPoint(x: w, y: h - cornerLength))
            context.stroke(br, with: .color(color), style: lineCap)
        }
    }

    // MARK: - Person Silhouette

    private var personSilhouette: some View {
        VStack(spacing: 8) {
            // Head
            Circle()
                .fill(color)
                .frame(width: size * 0.35, height: size * 0.35)

            // Shoulders
            Canvas { context, size in
                let w = size.width
                let h = size.height
                var shoulder = Path()
                shoulder.move(to: CGPoint(x: 0, y: h))
                shoulder.addQuadCurve(to: CGPoint(x: w, y: h), control: CGPoint(x: w * 0.5, y: 0))
                shoulder.closeSubpath()
                context.fill(shoulder, with: .color(color))
            }
            .frame(width: size * 0.7, height: size * 0.3)
        }
        .offset(y: 10)
    }
}

#Preview {
    FaceScanPlaceholderView()
}
