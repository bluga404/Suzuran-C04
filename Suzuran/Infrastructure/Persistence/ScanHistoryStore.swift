import Foundation
import Combine

/// Persists scan history as a JSON file in the app's Documents directory.
/// Max one scan per calendar day — rescanning on the same day overwrites the existing record.
final class ScanHistoryStore: ObservableObject {

    @Published private(set) var records: [ScanRecord] = []

    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("scan_history.json")
        self.records = Self.load(from: fileURL)
    }

    // MARK: - Public API

    /// Saves a scan result. If a record already exists for today, it is replaced.
    func save(_ result: FaceScanResultModel) {
        let today = Calendar.current.startOfDay(for: Date())

        let frontImageData = result.zoneSummaries
            .first(where: { $0.zone == .front })?.imageData
            
        let frontMarkers = result.zoneSummaries
            .first(where: { $0.zone == .front })?.markers
            
        var thumbnails: [ScanRecord.FaceArea: Data] = [:]
        var areaCounts: [ScanRecord.AcneAreaCount] = []
        var areaTypeCountsMap: [ScanRecord.FaceArea: [ScanRecord.AcneTypeCount]] = [:]
        var areaMarkersMap: [ScanRecord.FaceArea: [MarkerModel]] = [:]

        for subZone in result.subZoneSummaries {
            if let area = ScanRecord.FaceArea(rawValue: subZone.label) {
                if let data = subZone.imageData {
                    thumbnails[area] = data
                }
                areaCounts.append(ScanRecord.AcneAreaCount(area: area, count: subZone.acneCount))

                var typeMap: [AcneType: Int] = [:]
                for marker in subZone.markers {
                    typeMap[marker.acneType, default: 0] += 1
                }
                let typeCounts = AcneType.allCases.filter { $0 != .unknown }.map { type in
                    ScanRecord.AcneTypeCount(acneType: type, count: typeMap[type] ?? 0)
                }
                areaTypeCountsMap[area] = typeCounts
                
                if !subZone.markers.isEmpty {
                    areaMarkersMap[area] = subZone.markers
                }
            }
        }

        let record = ScanRecord(
            id: result.id,
            date: today,
            frontImageData: frontImageData,
            skinScore: result.skinScore,
            totalAcneCount: result.totalAcneCount,
            severity: result.overallSeverity,
            acneTypeCounts: result.acneTypeSummaries.map {
                ScanRecord.AcneTypeCount(acneType: $0.acneType, count: $0.count)
            },
            acneAreaCounts: areaCounts,
            subZoneThumbnails: thumbnails.isEmpty ? nil : thumbnails,
            areaTypeCounts: areaTypeCountsMap.isEmpty ? nil : areaTypeCountsMap,
            frontMarkers: frontMarkers,
            areaMarkers: areaMarkersMap.isEmpty ? nil : areaMarkersMap
        )

        // Remove any existing record for the same calendar day
        records.removeAll { Calendar.current.isDate($0.date, inSameDayAs: today) }
        records.append(record)
        // Sort newest first
        records.sort { $0.date > $1.date }

        persist()
    }

    /// Deletes a specific record.
    func delete(_ record: ScanRecord) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    // MARK: - Private

    private func persist() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[ScanHistoryStore] ❌ Failed to persist: \(error)")
        }
    }

    private static func load(from url: URL) -> [ScanRecord] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoded = (try? JSONDecoder().decode([ScanRecord].self, from: data)) ?? []
        return decoded.sorted { $0.date > $1.date }
    }
}
