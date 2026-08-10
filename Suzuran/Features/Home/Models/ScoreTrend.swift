import Foundation

/// Represents the direction of change in skin health score compared to a previous scan.
enum ScoreTrend: Equatable {
    case noPreviousData
    case improved
    case declined
    case unchanged
}
