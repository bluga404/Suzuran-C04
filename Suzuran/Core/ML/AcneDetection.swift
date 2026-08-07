import Foundation
import SwiftUI

// MARK: - Acne Type

enum AcneType: String, CaseIterable, Sendable {
    case comedones
    case papules
    case pustules
    case nodules
    case cysts

    nonisolated var displayName: String {
        switch self {
        case .comedones: return "Comedones"
        case .papules: return "Papules"
        case .pustules: return "Pustules"
        case .nodules: return "Nodules"
        case .cysts: return "Cysts"
        }
    }

    /// Severity weight from PRD §2.2.2 & user updates
    nonisolated var severityWeight: Float {
        switch self {
        case .comedones: return 0.5
        case .papules: return 1
        case .pustules: return 2
        case .nodules: return 3
        case .cysts: return 4
        }
    }

    nonisolated var color: Color {
        switch self {
        case .comedones: return .cyan
        case .papules: return .yellow
        case .pustules: return .orange
        case .nodules: return .red
        case .cysts: return Color(red: 0.8, green: 0.0, blue: 0.8) // Purple/Magenta for cysts
        }
    }

    /// Maps model output label to AcneType, handling various label formats
    nonisolated static func from(label: String) -> AcneType? {
        let normalized = label.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")

        switch normalized {
        case "comedones", "whitehead_blackhead", "whitehead_&_blackhead", "comedo", "whitehead", "blackhead", "0", "5":
            return .comedones
        case "papules", "papule", "3":
            return .papules
        case "pustules", "pustule", "pustular", "4":
            return .pustules
        case "nodule", "nodules", "2":
            return .nodules
        case "cyst", "cysts", "1":
            return .cysts
        default:
            break
        }

        // Partial match fallback
        if normalized.contains("comedo") || normalized.contains("whitehead") || normalized.contains("blackhead") {
            return .comedones
        }
        if normalized.contains("papul") { return .papules }
        if normalized.contains("pustul") { return .pustules }
        if normalized.contains("nodul") { return .nodules }
        if normalized.contains("cyst") { return .cysts }

        return nil
    }
}

// MARK: - Acne Detection

struct AcneDetection: Identifiable, Sendable {
    let id: UUID
    let acneType: AcneType
    let confidence: Float
    /// Bounding box in Vision normalized coordinates (origin bottom-left, 0–1 range)
    let boundingBox: CGRect

    nonisolated init(acneType: AcneType, confidence: Float, boundingBox: CGRect) {
        self.id = UUID()
        self.acneType = acneType
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}
