import Foundation

enum AppError: Error, Equatable {
    case networkUnavailable
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case decoding
    case validation(message: String)
    case server(message: String)
    case unknown(message: String)

    var userMessage: String {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .forbidden:
            return "You do not have access to this action."
        case .notFound:
            return "The requested resource was not found."
        case .decoding:
            return "We could not process the response from the server."
        case let .validation(message):
            return message
        case let .server(message):
            return message
        case let .unknown(message):
            return message
        }
    }
}
