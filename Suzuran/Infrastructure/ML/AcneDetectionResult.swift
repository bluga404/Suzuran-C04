import Foundation
import CoreGraphics

struct AcneDetectionResult: Equatable {
    let label: String
    let confidence: Float
    let boundingBox: CGRect
}
