import Foundation

/// Tracks the availability of different scan types for determining home state.
struct ScanAvailability: Equatable {
    let hasFaceScan: Bool
    let hasIngredientScan: Bool
    let hasPreviousFaceScan: Bool
}
