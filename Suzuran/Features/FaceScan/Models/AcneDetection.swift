import Foundation
import CoreGraphics

struct AcneDetection: Identifiable, Equatable, Codable {
    let id: UUID
    let acneType: AcneType
    let confidence: Double
    let normalizedBoundingBox: CGRect  // Already in 0–1 space (top-left origin)

    init(
        id: UUID = UUID(),
        acneType: AcneType,
        confidence: Double,
        normalizedBoundingBox: CGRect
    ) {
        self.id = id
        self.acneType = acneType
        self.confidence = confidence
        self.normalizedBoundingBox = normalizedBoundingBox
    }

    // MARK: - Codable

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
        normalizedBoundingBox = CGRect(x: x, y: y, width: width, height: height)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(acneType, forKey: .acneType)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(normalizedBoundingBox.origin.x, forKey: .x)
        try container.encode(normalizedBoundingBox.origin.y, forKey: .y)
        try container.encode(normalizedBoundingBox.size.width, forKey: .width)
        try container.encode(normalizedBoundingBox.size.height, forKey: .height)
    }
}
