//
//  LiveCursorTick.swift
//  Suzuran — Views/Components/
//
//  Bright capsule that orbits the oval tick ring in real time,
//  tracking the user's current head direction.
//
//  Uses the same ellipse parametric math as FaceTickRing so the cursor
//  rides exactly on the oval surface, matching the tick positions.
//

import SwiftUI

/// A bright capsule that orbits the face oval at the user's live head direction.
///
/// Visual design:
///   • White fill      — distinct from the green completed ticks.
///   • Inner glow      — tight white shadow (radius 6) for sharpness.
///   • Outer halo      — wide green shadow (radius 20) bleeding onto nearby ticks.
///   • Height 28 pt    — taller than a done-tick (22 pt) so it stands out clearly.
///
/// Position & orientation:
///   Derived from the same ellipse parametric equations used by TickMark,
///   ensuring the cursor sits on the oval surface and faces outward.
///
/// Wrap-safety:
///   `angleDegrees` is an *accumulated* (unbounded) value from ARFaceViewModel.
///   sin/cos handle the periodicity correctly; SwiftUI animates the short arc.
struct LiveCursorTick: View {

    let angleDegrees: Double   // accumulated, wrap-safe
    let ovalWidth:    CGFloat
    let ovalHeight:   CGFloat

    private let cursorWidth:  CGFloat = 6
    private let cursorHeight: CGFloat = 32

    // Ellipse geometry
    private var semiX: CGFloat { ovalWidth  / 2 }
    private var semiY: CGFloat { ovalHeight / 2 }
    private var θ: Double { angleDegrees * .pi / 180.0 }

    // Point on ellipse
    private var ellipseX: CGFloat { semiX * CGFloat(sin(θ)) }
    private var ellipseY: CGFloat { -semiY * CGFloat(cos(θ)) }

    // Outward normal
    private var normalX: CGFloat { semiY * CGFloat(sin(θ)) }
    private var normalY: CGFloat { -semiX * CGFloat(cos(θ)) }
    private var normalMag: CGFloat { sqrt(normalX * normalX + normalY * normalY) }

    // Tilt angle so the cursor points outward from the oval surface
    private var tiltDeg: Double { atan2(Double(normalX), Double(-normalY)) * 180 / .pi }

    // Cursor centre: ellipse point + (cursorHeight/2) along outward normal
    private var offsetX: CGFloat { ellipseX + (normalX / normalMag) * (cursorHeight / 2) }
    private var offsetY: CGFloat { ellipseY + (normalY / normalMag) * (cursorHeight / 2) }

    var body: some View {
        Capsule()
            .fill(Color.white)
            .frame(width: cursorWidth, height: cursorHeight)
            .shadow(color: Color.white.opacity(0.95), radius: 6)
            .shadow(color: Color.scanGreen.opacity(0.70), radius: 20)
            .rotationEffect(.degrees(tiltDeg))
            .offset(x: offsetX, y: offsetY)
            .animation(
                .interactiveSpring(response: 0.10, dampingFraction: 0.80),
                value: angleDegrees
            )
    }
}
