//
//  AcneDetection.swift
//  Suzuran — Models/
//
//  Data types for the YOLOv8 acne-detection pipeline.
//
//  Model facts (from best_model_coreml.mlpackage binary inspection):
//    • Architecture : YOLOv8 26m (Ultralytics 8.4.115)
//    • Input        : "image" — 640 × 640 px, RGB
//    • Output       : "var_1552" — shape [1, 10, 8400]
//                     channels 0-3 = (cx, cy, w, h) in 0-640 pixel space
//                     channels 4-9 = class probabilities (sigmoid-activated)
//    • NMS          : NOT built-in — applied manually in AcneDetectionViewModel
//    • Classes      : {0:blackhead, 1:cyst, 2:nodule, 3:papule, 4:pustule, 5:whitehead}
//

import SwiftUI
import ARKit
import simd

// MARK: - ARSnapshot

/// A timestamped snapshot of the AR state, used to map 2D ML detections back to the 3D face mesh.
struct ARSnapshot: Equatable {
    let id = UUID()
    let pixelBuffer: CVPixelBuffer
    let camera: ARCamera
    let faceTransform: simd_float4x4
    let vertices: [SIMD3<Float>]
    let geometry: ARFaceGeometry

    static func == (lhs: ARSnapshot, rhs: ARSnapshot) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - AcneClass

/// The six acne lesion types the model can detect.
/// Raw values match the model's class indices exactly.
enum AcneClass: Int, CaseIterable, Identifiable {

    case blackhead = 0
    case cyst      = 1
    case nodule    = 2
    case papule    = 3
    case pustule   = 4
    case whitehead = 5

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .blackhead: return "Blackhead"
        case .cyst:      return "Cyst"
        case .nodule:    return "Nodule"
        case .papule:    return "Papule"
        case .pustule:   return "Pustule"
        case .whitehead: return "Whitehead"
        }
    }

    var description: String {
        switch self {
        case .blackhead: return "Open clogged pore (comedone)"
        case .cyst:      return "Deep, pus-filled, painful lump"
        case .nodule:    return "Hard, deep inflamed nodule"
        case .papule:    return "Small, raised inflamed bump"
        case .pustule:   return "White or yellow pus-filled bump"
        case .whitehead: return "Closed clogged pore (comedone)"
        }
    }

    var severity: SeverityLevel {
        switch self {
        case .cyst, .nodule:          return .severe
        case .papule, .pustule:       return .moderate
        case .blackhead, .whitehead:  return .mild
        }
    }

    /// Brand color for bounding boxes and UI accents.
    var color: Color {
        switch self {
        case .blackhead: return Color(red: 0.60, green: 0.60, blue: 0.60) // neutral grey
        case .cyst:      return Color(red: 0.61, green: 0.36, blue: 0.90) // purple
        case .nodule:    return Color(red: 0.94, green: 0.28, blue: 0.44) // red
        case .papule:    return Color(red: 1.00, green: 0.55, blue: 0.26) // orange
        case .pustule:   return Color(red: 1.00, green: 0.82, blue: 0.40) // amber
        case .whitehead: return Color(red: 0.92, green: 0.89, blue: 0.82) // cream
        }
    }

    var icon: String {
        switch self {
        case .blackhead: return "circle.fill"
        case .cyst:      return "exclamationmark.circle.fill"
        case .nodule:    return "exclamationmark.triangle.fill"
        case .papule:    return "dot.circle.fill"
        case .pustule:   return "circle.dotted.and.circle"
        case .whitehead: return "circle"
        }
    }
}

// MARK: - SeverityLevel

/// Overall skin condition severity derived from the most serious detected class.
enum SeverityLevel: Comparable {
    case mild, moderate, severe

    var displayName: String {
        switch self {
        case .mild:     return "Mild"
        case .moderate: return "Moderate"
        case .severe:   return "Severe"
        }
    }

    var color: Color {
        switch self {
        case .mild:     return Color(red: 0.02, green: 0.84, blue: 0.63) // mint green
        case .moderate: return Color(red: 1.00, green: 0.70, blue: 0.28) // amber
        case .severe:   return Color(red: 0.94, green: 0.28, blue: 0.44) // crimson
        }
    }

    var icon: String {
        switch self {
        case .mild:     return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.circle.fill"
        case .severe:   return "exclamationmark.triangle.fill"
        }
    }

    var recommendation: String {
        switch self {
        case .mild:
            return "Good skin health. Maintain a gentle cleansing routine."
        case .moderate:
            return "Consider a targeted topical treatment. Consult a dermatologist if persistent."
        case .severe:
            return "We recommend consulting a licensed dermatologist for a personalised treatment plan."
        }
    }
}

// MARK: - AcneDetectionResult

/// One confirmed detection returned by the CoreML pipeline after NMS.
struct AcneDetectionResult: Identifiable {

    let id = UUID()

    /// Detected lesion type.
    let acneClass: AcneClass

    /// Model confidence score, 0–1.
    let confidence: Float

    /// The index of the ARFaceGeometry vertex this detection maps to.
    let vertexIndex: Int

    /// The exact 3D coordinate of that vertex in the face's local coordinate space.
    let localPosition: SIMD3<Float>
}
