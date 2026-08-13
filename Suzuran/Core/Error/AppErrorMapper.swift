import Foundation

enum AppErrorMapper {
    static func map(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return .networkUnavailable
            case .timedOut:
                return .timeout
            default:
                return .unknown(message: urlError.localizedDescription)
            }
        }

        return .unknown(message: error.localizedDescription)
    }
}
