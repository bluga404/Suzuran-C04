//
//  ARFaceViewModel.swift
//  Suzuran — ViewModels/
//
//  Responsibilities:
//    • Owns and manages the ARSession lifecycle (start / pause / reset).
//    • Receives per-frame face-anchor data from ARSCNViewDelegate.
//    • Reads ambient-light estimates via ARSessionDelegate (5 hz).
//    • Publishes UI-ready state: completedSegments, faceDetected,
//      currentAngleDegrees, lightingCondition, isCalibrating.
//
//  Performance contract
//  ─────────────────────────────────────────────────────────────────────
//  ARKit fires renderer(didUpdate:) at ~60 fps on a background thread.
//  To stay within SwiftUI's ~32 hz @Published rate limit:
//   1. Frame throttle  — main-thread dispatches capped at ~30 hz.
//   2. No-op guard     — angle published only when shift ≥ 0.5°;
//                        segments only when not already marked.
//   3. Lighting check  — ARSessionDelegate dispatches at ~5 hz,
//                        only on condition change (zero extra load).
//   4. Weak capture    — all async closures use [weak self].
//
//  Neutral pose calibration
//  ─────────────────────────────────────────────────────────────────────
//  ARFaceAnchor.transform is in WORLD space (gravity-aligned, +Y up).
//  When the phone is held below/above eye level the face's natural
//  "looking at screen" posture carries a constant pitch offset.
//  Without compensation:
//    • The resting position parks the cursor at a fixed ring position.
//    • Opposite segments become unreachable without extreme head movement.
//    • R may hover exactly at movementThreshold, causing flicker.
//
//  Fix: sample the first `calibrationFrames` throttled frames (~1 s) to
//  compute the user's neutral pitch and yaw, then subtract that offset
//  from every subsequent measurement. This re-centres the coordinate
//  system on whatever angle the user naturally holds the phone.
//

import ARKit
import Combine
import UIKit

final class ARFaceViewModel: NSObject, ObservableObject, ARSCNViewDelegate {

    // MARK: - AR Session

    let session = ARSession()

    // MARK: - Published State

    /// 120 boolean flags — one per 3° slice of the full 360° circle.
    @Published var completedSegments: [Bool]         = Array(repeating: false, count: 120)
    /// True once ARKit detects a face anchor in the scene.
    @Published var faceDetected:       Bool           = false
    /// Live head-direction angle (accumulated, wrap-safe). nil = no face.
    @Published var currentAngleDegrees: Double?       = nil
    /// Current ambient lighting quality.
    @Published var lightingCondition:  LightingCondition = .checking
    /// True while collecting the neutral-pose calibration samples (~1 s).
    @Published var isCalibrating:      Bool           = false

    var isComplete: Bool { completedSegments.allSatisfy { $0 } }

    // MARK: - Scanning Constants

    private let movementThreshold:    Float  = 0.20     // radians (~11.5°)
    private let anglePublishThreshold: Double = 0.5      // degrees

    // MARK: - Lighting Thresholds (lm/m²)

    private let tooDarkThreshold:    CGFloat = 500
    private let tooBrightThreshold:  CGFloat = 2_500

    // MARK: - Throttle Timestamps (background thread, single-writer)

    private var lastDispatchTime:   CFAbsoluteTime = 0
    private let frameInterval:      CFAbsoluteTime = 1.0 / 30.0  // ~30 hz

    private var lastLightCheckTime: CFAbsoluteTime = 0
    private let lightCheckInterval: CFAbsoluteTime = 1.0 / 5.0   // ~5 hz

    // MARK: - Neutral Pose Calibration (background thread)

    /// Number of throttled frames to sample for the neutral pose estimate.
    /// At 30 hz, 30 frames ≈ 1 second of stable observation.
    private let calibrationFrames = 30

    /// Frames collected so far in the current calibration window.
    private var calibrationSamples = 0

    /// Running mean of pitch observed during calibration (world-space radians).
    private var neutralPitch: Float = 0

    /// Running mean of yaw observed during calibration (world-space radians).
    private var neutralYaw:   Float = 0

    // MARK: - Angle Accumulator (background thread)

    private var accumulatedAngle:   Double = 0
    private var lastPublishedAngle: Double = 0

    // MARK: - Haptics

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Session Lifecycle

    func startSession() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("⚠️ ARFaceTracking requires a TrueDepth camera.")
            return
        }
        haptic.prepare()
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        session.delegate = self
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func pauseSession() {
        session.pause()
    }

    func resetScan() {
        completedSegments   = Array(repeating: false, count: 120)
        faceDetected        = false
        currentAngleDegrees = nil
        lightingCondition   = .checking
        isCalibrating       = false
        resetCalibration()
        startSession()
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let face = anchor as? ARFaceAnchor else { return }
        let t     = face.transform
        let pitch = asin(-t.columns.2.y)
        let yaw   = atan2(t.columns.2.x, t.columns.2.z)
        processHeadMovement(pitch: pitch, yaw: yaw)
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARFaceAnchor else { return }
        // Reset calibration so it restarts fresh each time a face enters frame.
        resetCalibration()
        DispatchQueue.main.async { [weak self] in
            self?.faceDetected   = true
            self?.isCalibrating  = true   // calibration begins immediately
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARFaceAnchor else { return }
        // Reset calibration so it re-runs when the face reappears.
        resetCalibration()
        DispatchQueue.main.async { [weak self] in
            self?.faceDetected        = false
            self?.currentAngleDegrees = nil
            self?.isCalibrating       = false
        }
    }

    // MARK: - Calibration Helpers (background thread)

    private func resetCalibration() {
        calibrationSamples = 0
        neutralPitch       = 0
        neutralYaw         = 0
        accumulatedAngle   = 0
        lastPublishedAngle = 0
        lastDispatchTime   = 0
    }

    // MARK: - Head Movement Processing (throttled, background thread)

    private func processHeadMovement(pitch: Float, yaw: Float) {

        // ── Frame throttle: ~30 hz cap ─────────────────────────────────
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastDispatchTime >= frameInterval else { return }
        lastDispatchTime = now

        // ── Calibration phase (~1 second) ──────────────────────────────
        // Sample the resting pitch/yaw to compute the phone's hold angle.
        // Segments are NOT marked during calibration. The cursor is hidden.
        if calibrationSamples < calibrationFrames {
            let n = Float(calibrationSamples)
            neutralPitch = (neutralPitch * n + pitch) / (n + 1)
            neutralYaw   = (neutralYaw   * n + yaw  ) / (n + 1)
            calibrationSamples += 1

            let justFinished = calibrationSamples == calibrationFrames
            if justFinished {
                // Transition to scanning on the main thread.
                DispatchQueue.main.async { [weak self] in
                    self?.isCalibrating = false
                }
            }
            return  // no segment marking while calibrating
        }

        // ── Scanning phase ─────────────────────────────────────────────
        // Subtract the calibrated neutral pose so the coordinate origin
        // is the user's natural "looking at screen" position, regardless
        // of where they're holding the phone.
        let adjPitch = pitch - neutralPitch
        let adjYaw   = yaw   - neutralYaw

        // Step A — Magnitude in the adjusted space
        let R = sqrt(adjYaw * adjYaw + adjPitch * adjPitch)

        // Step C — Direction angle (−adjYaw mirrors selfie camera lateral flip)
        let thetaRaw = atan2(adjPitch, -adjYaw)
        var thetaComputed = thetaRaw * (180.0 / .pi)
        if thetaComputed < 0 { thetaComputed += 360.0 }

        // Step D — Coordinate correction: (270° − θ) mod 360
        //   right→RIGHT, up→TOP, left→LEFT, down→BOTTOM
        let thetaDisplay = (270.0 - Double(thetaComputed) + 360.0)
                            .truncatingRemainder(dividingBy: 360.0)

        let index      = Int(thetaDisplay / 3.0) % 120
        let shouldMark = R >= movementThreshold

        // Wrap-safe accumulated angle (prevents SwiftUI animating "long way round")
        let lastNorm = accumulatedAngle.truncatingRemainder(dividingBy: 360)
        var delta = thetaDisplay - (lastNorm < 0 ? lastNorm + 360 : lastNorm)
        if delta >  180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        accumulatedAngle += delta

        let newAngle     = accumulatedAngle
        let angleChanged = abs(newAngle - lastPublishedAngle) >= anglePublishThreshold
        guard angleChanged || shouldMark else { return }
        if angleChanged { lastPublishedAngle = newAngle }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            if angleChanged {
                self.currentAngleDegrees = newAngle
                if !self.faceDetected { self.faceDetected = true }
            }

            // Segment marking: gated on good lighting AND calibration done.
            guard shouldMark,
                  !self.isCalibrating,
                  self.lightingCondition == .good,
                  !self.completedSegments[index] else { return }
            self.completedSegments[index] = true
            self.haptic.impactOccurred(intensity: 0.55)
        }
    }
}

// MARK: - ARSessionDelegate (lighting estimation, ~5 hz)

extension ARFaceViewModel: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastLightCheckTime >= lightCheckInterval else { return }
        lastLightCheckTime = now

        guard let estimate = frame.lightEstimate else { return }
        let intensity = estimate.ambientIntensity

        let newCondition: LightingCondition
        switch intensity {
        case ..<tooDarkThreshold:   newCondition = .tooDark
        case tooBrightThreshold...: newCondition = .tooBright
        default:                    newCondition = .good
        }

        guard newCondition != lightingCondition else { return }
        DispatchQueue.main.async { [weak self] in self?.lightingCondition = newCondition }
    }
}
