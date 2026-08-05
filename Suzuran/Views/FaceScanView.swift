//
//  FaceScanView.swift
//  Suzuran — Views/
//
//  Root view for the face-scan enrollment screen.
//
//  Layer order (ZStack, back → front):
//    1. Live AR camera feed     (ARViewContainer, full-screen)
//    2. Radial vignette         (depth / focus darkening)
//    3. Ring cluster            (FaceOvalGuide + FaceTickRing + LiveCursorTick
//                                + LightingWarningBanner)
//    4. Reset button            (top-right, always visible)
//    5. Instruction badge       (bottom, InstructionBadge + Scan Again button)
//
//  Oval sizing:
//    ovalWidth  = 82% of screen width  → large close-up framing
//    ovalHeight = 60% of screen height → tall portrait face shape
//    All ring components share the same ovalWidth/ovalHeight so ticks,
//    cursor, and oval guide are always perfectly aligned.
//

import SwiftUI

struct FaceScanView: View {

    @StateObject private var viewModel      = ARFaceViewModel()
    @StateObject private var detectionVM    = AcneDetectionViewModel()
    @State       private var showResults    = false

    // MARK: - Derived State

    private var completedCount: Int {
        viewModel.completedSegments.filter { $0 }.count
    }

    private var ringScanActive: Bool {
        viewModel.lightingCondition == .good
    }

    private var instructionText: String {
        switch viewModel.lightingCondition {
        case .checking:  return "Checking environment…"
        case .tooDark:   return "Move to a brighter area"
        case .tooBright: return "Reduce glare or direct light"
        case .good:
            if viewModel.isCalibrating        { return "Hold still for a moment…" }
            if detectionVM.isAnalyzing        { return "Analysing scan…" }
            if viewModel.isComplete           { return "Scan Complete!" }
            if viewModel.faceDetected         { return "Now turn your head slowly" }
            return "Put your face in the frame"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 1. AR Camera Feed
            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()

            // 2. Radial Vignette
            RadialGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.55)]),
                center: .center,
                startRadius: 160,
                endRadius: 480
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // 3. Ring Cluster
            ringCluster
                .allowsHitTesting(false)

            // 4. Reset Button
            resetButton

            // 5. Bottom Badge
            bottomBadge
        }
        .onChange(of: viewModel.activeSnapshot) { _, snapshot in
            guard let snapshot else { return }
            detectionVM.analyse(snapshot: snapshot)
        }
        .onChange(of: viewModel.finalFaceGeometry) { _, geom in
            if geom != nil && !detectionVM.isAnalyzing {
                viewModel.pauseSession()
                showResults = true
            }
        }
        .onChange(of: detectionVM.isAnalyzing) { _, analyzing in
            if !analyzing, viewModel.finalFaceGeometry != nil {
                viewModel.pauseSession()
                showResults = true
            }
        }
        .fullScreenCover(isPresented: $showResults, onDismiss: {
            viewModel.resetScan()
            detectionVM.detections.removeAll()
        }) {
            if let geom = viewModel.finalFaceGeometry {
                AcneResultsView(
                    faceGeometry: geom,
                    detections:   detectionVM.detections
                )
            }
        }
    }

    // MARK: - Ring Cluster

    private var ringCluster: some View {
        GeometryReader { geo in
            // Centre the oval slightly above screen mid-point (portrait face zone)
            let center = CGPoint(
                x: geo.size.width  / 2,
                y: geo.size.height / 2 * 0.90
            )

            // Large oval dimensions — sized for close-up selfie capture
            let ovalWidth  = geo.size.width  * 0.82
            let ovalHeight = geo.size.height * 0.60

            ZStack {
                // Dashed oval face guide
                FaceOvalGuide(
                    width:      ovalWidth,
                    height:     ovalHeight,
                    isActive:   viewModel.faceDetected && ringScanActive,
                    isComplete: viewModel.isComplete
                )
                .position(center)

                // 120 tick marks arranged on the oval perimeter.
                // Dimmed to 30% when lighting is not confirmed.
                // Dimmed to 50% during calibration (not yet active).
                FaceTickRing(
                    completedSegments: viewModel.completedSegments,
                    ovalWidth:  ovalWidth,
                    ovalHeight: ovalHeight
                )
                .position(center)
                .opacity({
                    if !ringScanActive          { return 0.30 }
                    if viewModel.isCalibrating  { return 0.50 }
                    return 1.0
                }())
                .animation(.easeInOut(duration: 0.4), value: ringScanActive)
                .animation(.easeInOut(duration: 0.4), value: viewModel.isCalibrating)

                // Live direction cursor — hidden during calibration and poor lighting
                if ringScanActive, !viewModel.isCalibrating, let angle = viewModel.currentAngleDegrees {
                    LiveCursorTick(
                        angleDegrees: angle,
                        ovalWidth:    ovalWidth,
                        ovalHeight:   ovalHeight
                    )
                    .position(center)
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                }

                // Lighting warning — shown when lighting is outside bounds
                if viewModel.lightingCondition != .good {
                    LightingWarningBanner(
                        condition: viewModel.lightingCondition,
                        ovalWidth: ovalWidth
                    )
                    .position(center)
                    .transition(
                        .opacity.combined(with: .scale(scale: 0.92))
                        .animation(.spring(response: 0.4, dampingFraction: 0.75))
                    )
                }
            }
            .animation(.easeInOut(duration: 0.35), value: viewModel.lightingCondition)
        }
    }

    // MARK: - Reset Button

    private var resetButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        viewModel.resetScan()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 1))
                        )
                        .shadow(color: .black.opacity(0.30), radius: 8)
                }
                .padding(.top, 16)
                .padding(.trailing, 20)
                .overlay(
                    Circle()
                        .fill(Color.scanGreen)
                        .frame(width: 9, height: 9)
                        .offset(x: 14, y: -14)
                        .opacity(completedCount > 0 && !viewModel.isComplete ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: completedCount > 0),
                    alignment: .topTrailing
                )
            }
            Spacer()
        }
    }

    // MARK: - Bottom Badge

    private var bottomBadge: some View {
        VStack(spacing: 0) {
            Spacer()

            InstructionBadge(
                text:              instructionText,
                isComplete:        viewModel.isComplete,
                faceDetected:      viewModel.faceDetected,
                isCalibrating:     viewModel.isCalibrating,
                progress:          completedCount,
                lightingCondition: viewModel.lightingCondition
            )

            if viewModel.isComplete {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.resetScan()
                    }
                } label: {
                    Label("Scan Again", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1))
                        )
                }
                .padding(.top, 18)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer().frame(height: 56)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.isComplete)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.faceDetected)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.isCalibrating)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.lightingCondition)
    }
}

// MARK: - Preview

#Preview {
    FaceScanView()
}
