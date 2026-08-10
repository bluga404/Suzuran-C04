import Foundation

/// Represents the 6 possible UI states of the Home summary screen.
/// The state is determined by scan availability and score comparison.
enum HomeSummaryState: Equatable {
    case empty
    case faceOnly
    case complete
    case improvement
    case degradation
    case unchanged
}
