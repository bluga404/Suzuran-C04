import Foundation

protocol AppLogging {
    func info(_ message: String, file: String, line: Int)
    func error(_ message: String, file: String, line: Int)
}

extension AppLogging {
    func info(_ message: String, file: String = #fileID, line: Int = #line) {
        info(message, file: file, line: line)
    }

    func error(_ message: String, file: String = #fileID, line: Int = #line) {
        error(message, file: file, line: line)
    }
}

struct AppLogger: AppLogging {
    private let formatter: ISO8601DateFormatter = ISO8601DateFormatter()

    func info(_ message: String, file: String, line: Int) {
        log(level: "INFO", message: message, file: file, line: line)
    }

    func error(_ message: String, file: String, line: Int) {
        log(level: "ERROR", message: message, file: file, line: line)
    }

    private func log(level: String, message: String, file: String, line: Int) {
        #if DEBUG
        let timestamp = formatter.string(from: Date())
        print("[\(timestamp)] [\(level)] \(file):\(line) - \(message)")
        #endif
    }
}
