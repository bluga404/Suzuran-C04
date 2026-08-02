import CoreGraphics
import Foundation
import Vision

struct FacePoseAnalysis {
    let faceDetected: Bool
    let isFramed: Bool
    let isTargetSatisfied: Bool
    let stabilityScore: Double
    let hint: String
}

struct FaceScanPoseAnalyzer {
    private let minFaceArea: CGFloat = 0.15
    private let maxFaceArea: CGFloat = 0.58
    private let maxCenterOffset: CGFloat = 0.22
    private let maxRollRadians: Double = 0.20

    private let sideYawThreshold: Double = 0.20
    private let foreheadPitchThreshold: Double = -0.12
    private let chinPitchThreshold: Double = 0.12
    private let centerThreshold: Double = 0.08

    func analyze(observation: VNFaceObservation?, target: FaceScanArea) -> FacePoseAnalysis {
        guard let observation = observation else {
            return FacePoseAnalysis(
                faceDetected: false,
                isFramed: false,
                isTargetSatisfied: false,
                stabilityScore: 0,
                hint: "Place your face inside the frame."
            )
        }

        let boundingBox = observation.boundingBox
        let area = boundingBox.width * boundingBox.height
        let centerX = boundingBox.midX
        let centerY = boundingBox.midY

        let offsetX = abs(centerX - 0.5)
        let offsetY = abs(centerY - 0.5)

        let isFaceSizeValid = area >= minFaceArea && area <= maxFaceArea
        let isCentered = offsetX <= maxCenterOffset && offsetY <= maxCenterOffset

        let roll = observation.roll?.doubleValue ?? 0
        let yaw = observation.yaw?.doubleValue ?? 0
        let pitch = observation.pitch?.doubleValue ?? 0

        let isRollStable = abs(roll) <= maxRollRadians
        let hasLandmarks = observation.landmarks != nil

        let isFramed = isFaceSizeValid && isCentered && isRollStable && hasLandmarks

        guard isFramed else {
            return FacePoseAnalysis(
                faceDetected: true,
                isFramed: false,
                isTargetSatisfied: false,
                stabilityScore: framedScore(
                    faceSizeValid: isFaceSizeValid,
                    centeredX: offsetX,
                    centeredY: offsetY,
                    roll: roll,
                    landmarksReady: hasLandmarks
                ),
                hint: framingHint(
                    faceSizeValid: isFaceSizeValid,
                    centeredX: offsetX,
                    centeredY: offsetY,
                    roll: roll,
                    landmarksReady: hasLandmarks
                )
            )
        }

        let targetSatisfied: Bool
        let orientationProgress: Double

        switch target {
        case .rightCheek:
            targetSatisfied = yaw >= sideYawThreshold
            orientationProgress = progressAbove(value: yaw, threshold: sideYawThreshold)
        case .leftCheek:
            targetSatisfied = yaw <= -sideYawThreshold
            orientationProgress = progressAbove(value: -yaw, threshold: sideYawThreshold)
        case .forehead:
            targetSatisfied = pitch <= foreheadPitchThreshold
            orientationProgress = progressAbove(value: -pitch, threshold: -foreheadPitchThreshold)
        case .chin:
            targetSatisfied = pitch >= chinPitchThreshold
            orientationProgress = progressAbove(value: pitch, threshold: chinPitchThreshold)
        case .centerFace:
            targetSatisfied = abs(yaw) <= centerThreshold && abs(pitch) <= centerThreshold
            orientationProgress = centerProgress(yaw: yaw, pitch: pitch)
        }

        return FacePoseAnalysis(
            faceDetected: true,
            isFramed: true,
            isTargetSatisfied: targetSatisfied,
            stabilityScore: orientationProgress,
            hint: targetSatisfied ? "Hold still..." : target.instruction
        )
    }

    private func framingHint(
        faceSizeValid: Bool,
        centeredX: CGFloat,
        centeredY: CGFloat,
        roll: Double,
        landmarksReady: Bool
    ) -> String {
        if !faceSizeValid {
            return "Move closer and keep your whole face visible."
        }

        if centeredX > maxCenterOffset || centeredY > maxCenterOffset {
            return "Center your face inside the guide."
        }

        if abs(roll) > maxRollRadians {
            return "Keep your head upright."
        }

        if !landmarksReady {
            return "Improve lighting and keep your face uncovered."
        }

        return "Align your face to continue."
    }

    private func framedScore(
        faceSizeValid: Bool,
        centeredX: CGFloat,
        centeredY: CGFloat,
        roll: Double,
        landmarksReady: Bool
    ) -> Double {
        var score: Double = 0

        if faceSizeValid {
            score += 0.35
        }

        let centerComponent = 1.0 - min(1.0, Double((centeredX + centeredY) / (maxCenterOffset * 2)))
        score += centerComponent * 0.35

        let rollComponent = 1.0 - min(1.0, abs(roll) / maxRollRadians)
        score += rollComponent * 0.2

        if landmarksReady {
            score += 0.1
        }

        return max(0, min(1, score))
    }

    private func progressAbove(value: Double, threshold: Double) -> Double {
        guard threshold > 0 else { return 0 }
        let ratio = value / threshold
        return max(0, min(1, ratio))
    }

    private func centerProgress(yaw: Double, pitch: Double) -> Double {
        let yawScore = 1.0 - min(1.0, abs(yaw) / centerThreshold)
        let pitchScore = 1.0 - min(1.0, abs(pitch) / centerThreshold)
        return max(0, min(1, (yawScore + pitchScore) / 2.0))
    }
}
