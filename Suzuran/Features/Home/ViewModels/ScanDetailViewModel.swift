import Combine
import Foundation
import UIKit

/// Data model for the scan detail presentation layer.
struct ScanDetailData: Equatable {
    let scan: SkinScan
    let recommendations: [IngredientRecommendation]
}

/// ViewModel for the Scan Detail screen.
/// Loads a specific scan by ID and provides per-region breakdowns
/// with acne counts and type-specific recommendations.
@MainActor
final class ScanDetailViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<ScanDetailData> = .idle
    @Published var selectedRegion: FaceRegion? = nil // nil means "All"
    @Published private(set) var image: UIImage? = nil

    private let scanID: UUID
    private let skinScanRepository: SkinScanRepository
    private let historyStore: ScanHistoryStore?

    init(scanID: UUID, skinScanRepository: SkinScanRepository, historyStore: ScanHistoryStore? = nil) {
        self.scanID = scanID
        self.skinScanRepository = skinScanRepository
        self.historyStore = historyStore
    }

    /// Fetches the scan by ID, determines detected types, pre-selects the
    /// highest-count type, and publishes the loaded state.
    func load() async {
        state = .loading
        
        // Load image from history store if available
        if let historyStore = historyStore,
           let record = historyStore.records.first(where: { $0.id == scanID }),
           let frontData = record.frontImageData,
           let uiImage = UIImage(data: frontData) {
            self.image = uiImage
        }
        
        do {
            var finalScan: SkinScan? = try await skinScanRepository.scan(byID: scanID)
            
            // Fallback: If not in in-memory repo (e.g. historical record), reconstruct a partial SkinScan from ScanRecord
            if finalScan == nil, let record = historyStore?.records.first(where: { $0.id == scanID }) {
                var acneCounts: [AcneType: Int] = [:]
                for typeCount in record.acneTypeCounts {
                    acneCounts[typeCount.acneType] = typeCount.count
                }
                
                // Note: Historical ScanRecords do not store the intersection of Region x AcneType,
                // so regional filtering will show 0 for historical records.
                var regionCounts: [FaceRegion: [AcneType: Int]] = [:]
                for region in FaceRegion.allCases {
                    regionCounts[region] = [:]
                }
                
                finalScan = SkinScan(
                    id: record.id,
                    userID: UUID(),
                    createdAt: record.date,
                    overallScore: record.skinScore,
                    weightedAcneCount: 0,
                    gagsScore: 0,
                    acneCounts: acneCounts,
                    regionCounts: regionCounts,
                    regionGagsScores: [:],
                    imageReference: nil,
                    modelVersion: nil,
                    scanProtocolVersion: nil
                )
            }
            
            guard let scan = finalScan else {
                state = .failed(.notFound)
                return
            }

            let data = ScanDetailData(
                scan: scan,
                recommendations: []
            )
            state = .loaded(data)
        } catch {
            state = .failed(.unknown(message: error.localizedDescription))
        }
    }

    /// Returns the total count for the currently selected region (or all).
    var totalCountForSelected: Int {
        guard case .loaded(let data) = state else { return 0 }
        
        if let region = selectedRegion {
            let counts = data.scan.regionCounts[region] ?? [:]
            return counts.values.reduce(0, +)
        } else {
            return data.scan.acneCounts.values.reduce(0, +)
        }
    }
    
    /// Most detected acne type for the currently selected region (or all)
    var mostDetectedAcneType: AcneType? {
        let counts = countsByAcneType
        let filtered = counts.filter { $0.count > 0 }
        return filtered.max(by: { $0.count < $1.count })?.type
    }

    /// Returns per-acne-type counts for the currently selected region in priority order.
    var acneCountsForSelected: [(type: AcneType, count: Int)] {
        let priorityOrder: [AcneType] = [.whitehead, .blackhead, .papule, .pustule, .nodule, .cyst]
        let counts = countsByAcneType
        
        return priorityOrder.map { type in
            let count = counts.first(where: { $0.type == type })?.count ?? 0
            return (type: type, count: count)
        }
    }
    
    private var countsByAcneType: [(type: AcneType, count: Int)] {
        guard case .loaded(let data) = state else { return [] }
        
        if let region = selectedRegion {
            let dict = data.scan.regionCounts[region] ?? [:]
            return dict.map { (type: $0.key, count: $0.value) }
        } else {
            return data.scan.acneCounts.map { (type: $0.key, count: $0.value) }
        }
    }
}
