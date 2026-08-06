import Foundation
import CoreGraphics
import Vision

struct FaceZoneRegion {
    let zone: FaceZone
    /// Normalized rectangle relative to the face bounding box (0...1)
    let normalizedRect: CGRect
}

struct FaceLandmarkZoneMapper {
    /// Maps a VNFaceObservation to 5 face zones using its landmarks.
    static func mapZones(from observation: VNFaceObservation) -> [FaceZoneRegion]? {
        guard let landmarks = observation.landmarks,
              let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye,
              let leftEyebrow = landmarks.leftEyebrow,
              let rightEyebrow = landmarks.rightEyebrow,
              let nose = landmarks.nose,
              let noseCrest = landmarks.noseCrest,
              let outerLips = landmarks.outerLips,
              let faceContour = landmarks.faceContour else {
            return nil
        }
        
        var zones: [FaceZoneRegion] = []
        
        // --- 1. Forehead ---
        // Above eyebrows up to the top of the face bounding box.
        // We use the highest point of both eyebrows for the bottom of the forehead.
        let leftEyebrowMaxY = leftEyebrow.normalizedPoints.map { $0.y }.max() ?? 0
        let rightEyebrowMaxY = rightEyebrow.normalizedPoints.map { $0.y }.max() ?? 0
        let eyebrowsMaxY = max(leftEyebrowMaxY, rightEyebrowMaxY)
        
        let leftEyebrowMinX = leftEyebrow.normalizedPoints.map { $0.x }.min() ?? 0
        let rightEyebrowMaxX = rightEyebrow.normalizedPoints.map { $0.x }.max() ?? 1
        
        // Note: Vision's coordinate system origin is bottom-left.
        // y: eyebrowsMaxY to 1.0 (top of bounding box)
        let foreheadRect = CGRect(
            x: leftEyebrowMinX,
            y: eyebrowsMaxY,
            width: rightEyebrowMaxX - leftEyebrowMinX,
            height: 1.0 - eyebrowsMaxY
        ).clamped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        zones.append(FaceZoneRegion(zone: .forehead, normalizedRect: foreheadRect))
        
        // --- 2. Nose ---
        // Top: nose bridge (highest point of nose crest)
        // Bottom: nose base (lowest point of nose)
        // Left/Right: outermost points of nose
        let noseMinY = nose.normalizedPoints.map { $0.y }.min() ?? 0
        let noseMaxY = noseCrest.normalizedPoints.map { $0.y }.max() ?? 1
        let noseMinX = nose.normalizedPoints.map { $0.x }.min() ?? 0
        let noseMaxX = nose.normalizedPoints.map { $0.x }.max() ?? 1
        
        let noseRect = CGRect(
            x: noseMinX,
            y: noseMinY,
            width: noseMaxX - noseMinX,
            height: noseMaxY - noseMinY
        ).clamped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        zones.append(FaceZoneRegion(zone: .nose, normalizedRect: noseRect))
        
        // --- 3. Left Cheek ---
        // Top: below left eye
        // Bottom: height of nose base
        // Right: left side of nose
        // Left: left face contour
        let leftEyeMinY = leftEye.normalizedPoints.map { $0.y }.min() ?? 1
        let leftContourMinX = faceContour.normalizedPoints.filter { $0.x < 0.5 }.map { $0.x }.min() ?? 0
        
        let leftCheekRect = CGRect(
            x: leftContourMinX,
            y: noseMinY, // Same baseline as nose
            width: noseMinX - leftContourMinX,
            height: leftEyeMinY - noseMinY
        ).clamped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        zones.append(FaceZoneRegion(zone: .leftCheek, normalizedRect: leftCheekRect))
        
        // --- 4. Right Cheek ---
        // Top: below right eye
        // Bottom: height of nose base
        // Left: right side of nose
        // Right: right face contour
        let rightEyeMinY = rightEye.normalizedPoints.map { $0.y }.min() ?? 1
        let rightContourMaxX = faceContour.normalizedPoints.filter { $0.x > 0.5 }.map { $0.x }.max() ?? 1
        
        let rightCheekRect = CGRect(
            x: noseMaxX,
            y: noseMinY,
            width: rightContourMaxX - noseMaxX,
            height: rightEyeMinY - noseMinY
        ).clamped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        zones.append(FaceZoneRegion(zone: .rightCheek, normalizedRect: rightCheekRect))
        
        // --- 5. Chin ---
        // Top: below lower lip
        // Bottom: lowest point of face contour
        // Left/Right: bounded by inner contour
        let outerLipsMinY = outerLips.normalizedPoints.map { $0.y }.min() ?? 1
        let contourMinY = faceContour.normalizedPoints.map { $0.y }.min() ?? 0
        
        let chinRect = CGRect(
            x: leftEye.normalizedPoints.map { $0.x }.max() ?? 0,
            y: contourMinY,
            width: (rightEye.normalizedPoints.map { $0.x }.min() ?? 1) - (leftEye.normalizedPoints.map { $0.x }.max() ?? 0),
            height: outerLipsMinY - contourMinY
        ).clamped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        zones.append(FaceZoneRegion(zone: .chin, normalizedRect: chinRect))
        
        return zones
    }
}

extension CGRect {
    func clamped(to rect: CGRect) -> CGRect {
        // Returns the intersection, or a zero rect if they don't intersect
        let intersection = self.intersection(rect)
        if intersection.isNull {
            return .zero
        }
        return intersection
    }
}
