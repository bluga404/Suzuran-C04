import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var records: [ScanRecord] = []
    /// Compare mode toggle
    @Published var isCompareMode = false
    /// Currently selected records for compare (max 2)
    @Published var selectedRecordIDs: Set<UUID> = []

    /// Records grouped by month-year for section headers
    var groupedRecords: [(key: String, records: [ScanRecord])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")

        let grouped = Dictionary(grouping: records) { record -> String in
            formatter.string(from: record.date)
        }

        // Sort sections by date (newest first)
        return grouped.map { (key: $0.key, records: $0.value) }
            .sorted { lhs, rhs in
                guard let lDate = lhs.records.first?.date,
                      let rDate = rhs.records.first?.date else { return false }
                return lDate > rDate
            }
    }

    var selectedCount: Int { selectedRecordIDs.count }
    var canCompare: Bool { selectedRecordIDs.count == 2 }

    /// Returns the two selected ScanRecords (sorted oldest first for before → after).
    var selectedPair: (ScanRecord, ScanRecord)? {
        guard canCompare else { return nil }
        let selected = records.filter { selectedRecordIDs.contains($0.id) }
            .sorted { $0.date < $1.date }
        guard selected.count == 2 else { return nil }
        return (selected[0], selected[1])
    }

    let historyStore: ScanHistoryStore
    private var cancellable: AnyCancellable?

    // MARK: - Init

    init(historyStore: ScanHistoryStore) {
        self.historyStore = historyStore
        // Mirror store's records
        self.records = historyStore.records
        cancellable = historyStore.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.records = $0 }
    }

    // MARK: - Actions

    func toggleCompareMode() {
        isCompareMode.toggle()
        if !isCompareMode {
            selectedRecordIDs.removeAll()
        }
    }

    func toggleSelection(_ record: ScanRecord) {
        if selectedRecordIDs.contains(record.id) {
            selectedRecordIDs.remove(record.id)
        } else if selectedRecordIDs.count < 2 {
            selectedRecordIDs.insert(record.id)
        }
    }

    func isSelected(_ record: ScanRecord) -> Bool {
        selectedRecordIDs.contains(record.id)
    }
}
