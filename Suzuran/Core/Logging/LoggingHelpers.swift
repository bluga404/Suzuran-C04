import Foundation

enum LoggingHelpers {
    static func redactSensitive(_ input: String) -> String {
        var redacted = input

        if redacted.contains("AIza") {
            redacted = redacted.replacingOccurrences(
                of: #"AIza[A-Za-z0-9_-]+"#,
                with: "[REDACTED_API_KEY]",
                options: .regularExpression
            )
        }

        if redacted.contains("key=") {
            redacted = redacted.replacingOccurrences(
                of: #"key=[^&\s]+"#,
                with: "key=[REDACTED]",
                options: .regularExpression
            )
        }

        if redacted.count > 96 {
            let start = redacted.prefix(24)
            return String(start) + "…[REDACTED]"
        }

        return redacted
    }
}
