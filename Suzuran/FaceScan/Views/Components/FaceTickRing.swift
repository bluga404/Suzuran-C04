//
//  FaceTickRing.swift
//  Suzuran — Views/Components/
//
//  120-segment directional ring arranged on an OVAL (ellipse) path.
//  FaceTickRing  — container ZStack iterating over all 120 TickMarks.
//  TickMark      — single capsule positioned and oriented on the ellipse.
//
//  Ellipse parametric math (clockwise from top, SwiftUI screen coords):
//    P(θ) = (semiX·sinθ, −semiY·cosθ)
//    Outward normal direction at P: N = (semiY·sinθ, −semiX·cosθ)
//    Tick tilt from vertical: atan2(Nx, −Ny) = atan2(semiY·sinθ, semiX·cosθ)
//    Tick centre: P + (tickHeight/2)·N̂  (inner edge pinned to ellipse)
//

import SwiftUI

// MARK: - FaceTickRing

/// Renders all 120 tick marks arranged on an oval (ellipse) path.
///
/// .drawingGroup() is intentionally absent — it prevents per-view diffing
/// and blocks real-time colour/size updates. 120 Capsules is well within
/// SwiftUI's compositing budget on any TrueDepth-capable iPhone.
struct FaceTickRing: View {

    let completedSegments: [Bool]   // 120 elements
    let ovalWidth:  CGFloat
    let ovalHeight: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<120, id: \.self) { index in
                TickMark(
                    index: index,
                    isCompleted: completedSegments[index],
                    ovalWidth:  ovalWidth,
                    ovalHeight: ovalHeight
                )
            }
        }
    }
}

// MARK: - TickMark

/// One tick mark of the 120-segment oval ring.
///
/// Placement:
///   Each tick is positioned along the perimeter of the face oval ellipse.
///   The capsule is rotated so its long axis points along the ellipse's
///   outward normal at that angle — perpendicular to the oval surface.
///   The inner edge of the capsule is pinned to the ellipse boundary; when
///   the tick is completed it grows radially outward.
struct TickMark: View {

    let index:       Int
    let isCompleted: Bool
    let ovalWidth:   CGFloat
    let ovalHeight:  CGFloat

    // Semi-axes
    private var semiX: CGFloat { ovalWidth  / 2 }
    private var semiY: CGFloat { ovalHeight / 2 }

    // Angle for this tick (clockwise from 12 o'clock), in radians
    private var θ: Double { Double(index) * 3.0 * .pi / 180.0 }

    // Point on ellipse perimeter
    private var ellipseX: CGFloat { semiX * CGFloat(sin(θ)) }
    private var ellipseY: CGFloat { -semiY * CGFloat(cos(θ)) }

    // Outward normal at this point: N = (semiY·sinθ, −semiX·cosθ)
    private var normalX: CGFloat { semiY * CGFloat(sin(θ)) }
    private var normalY: CGFloat { -semiX * CGFloat(cos(θ)) }
    private var normalMag: CGFloat { sqrt(normalX * normalX + normalY * normalY) }

    // Tick tilt angle from vertical (so the capsule points outward)
    private var tiltDeg: Double { atan2(Double(normalX), Double(-normalY)) * 180 / .pi }

    // Dimensions driven by completion state
    private var tickWidth:  CGFloat { isCompleted ? TickGeometry.doneWidth  : TickGeometry.idleWidth  }
    private var tickHeight: CGFloat { isCompleted ? TickGeometry.doneHeight : TickGeometry.idleHeight }
    private var tickColor:  Color   { isCompleted ? .scanGreen              : .tickIdle               }

    // Tick centre: ellipse point + (tickHeight/2) along outward normal
    // This pins the INNER edge of the tick exactly on the ellipse perimeter.
    private var offsetX: CGFloat { ellipseX + (normalX / normalMag) * (tickHeight / 2) }
    private var offsetY: CGFloat { ellipseY + (normalY / normalMag) * (tickHeight / 2) }

    var body: some View {
        Capsule()
            .fill(tickColor)
            .frame(width: tickWidth, height: tickHeight)
            .rotationEffect(.degrees(tiltDeg))
            .offset(x: offsetX, y: offsetY)
            .shadow(
                color: isCompleted ? Color.scanGreen.opacity(0.75) : .clear,
                radius: isCompleted ? 6 : 0
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.50), value: isCompleted)
    }
}
