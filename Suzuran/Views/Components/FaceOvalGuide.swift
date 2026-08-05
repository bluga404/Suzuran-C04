//
//  FaceOvalGuide.swift
//  Suzuran — Views/Components/
//
//  Dashed ellipse that frames the user's face inside the scan ring.
//  Colour-shifts to scanGreen once a face is detected or scan completes.
//

import SwiftUI

struct FaceOvalGuide: View {

    let width:      CGFloat
    let height:     CGFloat
    let isActive:   Bool
    let isComplete: Bool

    @State private var pulsing = false

    private var strokeColor: Color {
        if isComplete { return .scanGreen.opacity(0.9) }
        if isActive   { return Color.white.opacity(0.40) }
        return Color.white.opacity(0.18)
    }

    var body: some View {
        Ellipse()
            .stroke(
                strokeColor,
                style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
            )
            .frame(width: width, height: height)
            .scaleEffect(pulsing && !isActive ? 1.015 : 1.0)
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulsing)
            .animation(.easeInOut(duration: 0.4), value: isActive)
            .animation(.easeInOut(duration: 0.4), value: isComplete)
            .onAppear { pulsing = true }
    }
}
