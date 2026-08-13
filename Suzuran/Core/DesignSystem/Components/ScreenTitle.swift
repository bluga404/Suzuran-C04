import Foundation

/// Single source of truth for the tab screen titles so views never consume raw strings.
enum ScreenTitle: Hashable {
    case summary
    case skincare
    case history
    case report

    var title: String {
        switch self {
        case .summary:  return "Summary"
        case .skincare: return "Skincare"
        case .history:  return "History"
        case .report:   return "Report"
        }
    }
}