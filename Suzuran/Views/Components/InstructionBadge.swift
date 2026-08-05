//
//  InstructionBadge.swift
//  Suzuran — Views/Components/
//
//  Frosted-glass capsule at the bottom of the scan screen.
//  Shows live state: lighting check → face detected → scanning progress → complete.
//

import SwiftUI

// MARK: - InstructionBadge

/// Bottom-of-screen status pill.
/// The leading indicator, background colour, and text all respond to the
/// current scan / lighting state.
struct InstructionBadge: View {

    let text:              String
    let isComplete:        Bool
    let faceDetected:      Bool
    let isCalibrating:     Bool
    let progress:          Int               // 0–120 captured segments
    let lightingCondition: LightingCondition

    // MARK: - Derived State

    private var isWarning: Bool {
        lightingCondition == .tooDark || lightingCondition == .tooBright
    }

    private var bgColor: Color {
        if isComplete    { return Color.scanGreen.opacity(0.85) }
        if isWarning     { return Color(red: 1.0, green: 0.65, blue: 0.10).opacity(0.20) }
        if isCalibrating { return Color.white.opacity(0.10) }
        if faceDetected  { return Color.white.opacity(0.14) }
        return Color.white.opacity(0.08)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {
            leadingIndicator

            VStack(alignment: .leading, spacing: 1) {
                Text(text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                if faceDetected && !isComplete && !isCalibrating {
                    Text("\(progress) / 120 captured")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.65))
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 13)
        .background(
            Capsule()
                .fill(bgColor)
                .background(Capsule().fill(.ultraThinMaterial))
                .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
                .clipShape(Capsule())
        )
        .shadow(
            color: isComplete ? Color.scanGreen.opacity(0.50) : .black.opacity(0.35),
            radius: 18
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: text)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isComplete)
    }

    // MARK: - Leading Indicator

    @ViewBuilder
    private var leadingIndicator: some View {
        if isComplete {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .transition(.scale.combined(with: .opacity))
        } else if isWarning {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.20))
                .transition(.scale.combined(with: .opacity))
        } else if lightingCondition == .checking {
            PulsingDot(color: .white.opacity(0.60))
        } else if isCalibrating {
            // White dot = face found, but pose sampling not yet done
            PulsingDot(color: .white.opacity(0.75))
        } else if faceDetected {
            PulsingDot(color: .scanGreen)
        } else {
            Circle()
                .fill(Color.white.opacity(0.50))
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - PulsingDot

/// Small animated circle used as a live-activity indicator inside the badge.
struct PulsingDot: View {

    let color: Color
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.85)
                    .repeatForever(autoreverses: true)
                ) { scale = 1.6 }
            }
    }
}
