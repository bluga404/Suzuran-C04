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
        var loaded = Self.load(from: fileURL)

        // Inject 9 August 2026 test dummy data if not present (allows testing Compare feature immediately)
        let aug9Dummy = DummyScanData.createAugust9Record()
        if !loaded.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: aug9Dummy.date) }) {
            loaded.append(aug9Dummy)
            loaded.sort { $0.date > $1.date }
        }

        self.records = loaded
    }

    // MARK: - Public API

    /// Saves a scan result. If a record already exists for today, it is replaced.
    func save(_ result: FaceScanResultModel) {
        let today = Calendar.current.startOfDay(for: Date())

        let frontImageData = result.zoneSummaries
            .first(where: { $0.zone == .front })?.imageData

        let record = ScanRecord(
            id: result.id,
            date: today,
            frontImageData: frontImageData,
            skinScore: result.skinScore,
            totalAcneCount: result.totalAcneCount,
            severity: result.overallSeverity,
            acneTypeCounts: result.acneTypeSummaries.map {
                ScanRecord.AcneTypeCount(acneType: $0.acneType, count: $0.count)
            }
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
