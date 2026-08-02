import Foundation

enum AcneAnalysisDomainError: Error, Equatable {
    case emptyImageData
    case invalidPayload(field: String)
    case lowConfidence
    case unknown(message: String)
}
