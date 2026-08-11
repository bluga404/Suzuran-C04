import Combine
import Foundation

/// Data model for the scan detail presentation layer.
struct ScanDetailData: Equatable {
    let scan: SkinScan
    /// Only acne types with count > 0, excluding .unknown
    let detectedTypes: [AcneType]
    let recommendations: [IngredientRecommendation]
}

/// ViewModel for the Scan Detail screen.
/// Loads a specific scan by ID and provides per-acne-type breakdowns
/// with region counts and type-specific recommendations.
@MainActor
final class ScanDetailViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<ScanDetailData> = .idle
    @Published var selectedAcneType: AcneType = .blackhead

    private let scanID: UUID
    private let skinScanRepository: SkinScanRepository

    init(scanID: UUID, skinScanRepository: SkinScanRepository) {
        self.scanID = scanID
        self.skinScanRepository = skinScanRepository
    }

    /// Fetches the scan by ID, determines detected types, pre-selects the
    /// highest-count type, and publishes the loaded state.
    func load() async {
        state = .loading
        do {
            guard let scan = try await skinScanRepository.scan(byID: scanID) else {
                state = .failed(.notFound)
                return
            }

            // Recognized types in priority order (excluding .unknown)
            let priorityOrder: [AcneType] = [.blackhead, .whitehead, .papule, .pustule, .nodule, .cyst]

            // Filter to types with count > 0
            let detectedTypes = priorityOrder.filter { type in
                (scan.acneCounts[type] ?? 0) > 0
            }

            // Pre-select the type with the highest count
            let highestType = detectedTypes.max { lhs, rhs in
                (scan.acneCounts[lhs] ?? 0) < (scan.acneCounts[rhs] ?? 0)
            }
            if let highest = highestType {
                selectedAcneType = highest
            }

            let data = ScanDetailData(
                scan: scan,
                detectedTypes: detectedTypes,
                recommendations: []
            )
            state = .loaded(data)
        } catch {
            state = .failed(.unknown(message: error.localizedDescription))
        }
    }

    /// Returns the total count for the currently selected acne type.
    var totalCountForSelected: Int {
        guard case .loaded(let data) = state else { return 0 }
        return data.scan.acneCounts[selectedAcneType] ?? 0
    }

    /// Returns per-region counts for the currently selected acne type in display order.
    var regionCountsForSelected: [(region: FaceRegion, count: Int)] {
        guard case .loaded(let data) = state else { return [] }
        return FaceRegion.displayOrder.map { region in
            let count = data.scan.regionCounts[region]?[selectedAcneType] ?? 0
            return (region: region, count: count)
        }
    }
}
