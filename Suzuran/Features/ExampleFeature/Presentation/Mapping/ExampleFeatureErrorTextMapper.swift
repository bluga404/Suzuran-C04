import Foundation

enum ExampleFeatureErrorTextMapper {
    static func message(for error: Error) -> String {
        if let domainError = error as? AcneAnalysisDomainError {
            switch domainError {
            case .emptyImageData:
                return "No image data was provided for analysis."
            case let .invalidPayload(field):
                return "Received invalid data for \(field)."
            case .lowConfidence:
                return "Analysis confidence is too low. Please capture a clearer image."
            case let .unknown(message):
                return message
            }
        }

        let appError = AppErrorMapper.map(error)
        return appError.userMessage
    }
}
