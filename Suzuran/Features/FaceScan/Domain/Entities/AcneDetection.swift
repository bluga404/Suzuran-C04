import Foundation
import CoreGraphics

enum AcneType: String, CaseIterable, Equatable, Codable {
    case blackhead
    case cyst
    case nodule
    case papule
    case pustule
    case whitehead
    case unknown

    init(rawLabel: String) {
        let normalized = rawLabel.lowercased()
        self = AcneType(rawValue: normalized) ?? .unknown
    }

    var displayName: String {
        switch self {
        case .blackhead: return "Blackhead"
        case .cyst: return "Cyst"
        case .nodule: return "Nodule"
        case .papule: return "Papule"
        case .pustule: return "Pustule"
        case .whitehead: return "Whitehead"
        case .unknown: return "Jerawat"
        }
    }
}

struct AcneDetection: Identifiable, Equatable, Codable {
    let id: UUID
    let acneType: AcneType
    let confidence: Double
    let boundingBox: CGRect

    init(id: UUID = UUID(), acneType: AcneType, confidence: Double, boundingBox: CGRect) {
        self.id = id
        self.acneType = acneType
        self.confidence = confidence
        self.boundingBox = boundingBox
    }

    enum CodingKeys: String, CodingKey {
        case id, acneType, confidence
        case x, y, width, height
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        acneType = try container.decode(AcneType.self, forKey: .acneType)
        confidence = try container.decode(Double.self, forKey: .confidence)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        boundingBox = CGRect(x: x, y: y, width: width, height: height)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(acneType, forKey: .acneType)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(boundingBox.origin.x, forKey: .x)
        try container.encode(boundingBox.origin.y, forKey: .y)
        try container.encode(boundingBox.size.width, forKey: .width)
        try container.encode(boundingBox.size.height, forKey: .height)
    }
}
