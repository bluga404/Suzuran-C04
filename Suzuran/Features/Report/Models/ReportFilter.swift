import Foundation

enum ReportMetric: String, CaseIterable, Identifiable {
    case skinScore = "Skin Score"
    case acneType = "Acne Type"

    var id: String { rawValue }
}

enum ReportRange: String, CaseIterable, Identifiable {
    case oneWeek = "1 Week"
    case oneMonth = "1 Month"
    case oneYear = "1 Year"

    var id: String { rawValue }
}
