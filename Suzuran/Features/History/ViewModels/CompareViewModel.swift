import Combine
import Foundation
import SwiftUI

// MARK: - CompareViewModel

/// Presentation logic for the Compare screen.
/// Owns the two selected ScanRecords, the available record pool (for date switching),
/// and all derived comparison values consumed by CompareView.
@MainActor
final class CompareViewModel: ObservableObject {

    // MARK: - Published State

    /// The "before" (older) record currently shown.
    @Published var recordA: ScanRecord
    /// The "after" (newer) record currently shown.
    @Published var recordB: ScanRecord

    /// Selected facial-area filter. nil = "All".
    @Published var selectedArea: ScanRecord.FaceArea? = nil

    /// Toggle between acne-by-area and acne-by-type breakdown table.
    @Published var acneMode: AcneBreakdownMode = .byType

    // MARK: - Read-only Data

    /// Full sorted history (oldest → newest). Used to populate date pickers.
    let allRecords: [ScanRecord]

    // MARK: - Init

    init(recordA: ScanRecord, recordB: ScanRecord, allRecords: [ScanRecord]) {
        self.recordA = recordA
        self.recordB = recordB
        // Sort oldest → newest so index 0 is the earliest record.
        self.allRecords = allRecords.sorted { $0.date < $1.date }
    }

    // MARK: - Computed: Skin Score

    var scoreDiff: Int { recordB.skinScore - recordA.skinScore }

    // MARK: - Computed: Total Acne (respects area filter)

    var filteredAcneA: Int {
        guard let area = selectedArea else { return recordA.totalAcneCount }
        return recordA.acneCount(for: area)
    }

    var filteredAcneB: Int {
        guard let area = selectedArea else { return recordB.totalAcneCount }
        return recordB.acneCount(for: area)
    }

    var filteredAcneDiff: Int { filteredAcneB - filteredAcneA }

    // MARK: - Computed: Insight

    /// Headline driven by score delta.
    var insightHeadline: String {
        if scoreDiff > 0 { return "Your Skin is Improving!" }
        if scoreDiff < 0 { return "Skin Needs Attention" }
        return "Skin Condition Stable"
    }

    /// Body text driven by actual acne delta and most-common type in the "after" record.
    var insightBody: String {
        let dateStr = Self.shortDateFormatter.string(from: recordA.date)
        let acneAbs = abs(filteredAcneDiff)
        let changeWord = filteredAcneDiff <= 0 ? "fewer" : "more"

        let mostCommonType = recordB.acneTypeCounts
            .filter { $0.acneType != .unknown }
            .max { $0.count < $1.count }?
            .acneType.displayName ?? ""

        let typeClause = mostCommonType.isEmpty
            ? ""
            : " and with \(mostCommonType.lowercased()) now being the most common type"

        return "Compared to \(dateStr), \(acneAbs) \(changeWord) acne detected\(typeClause)"
    }

    // MARK: - Computed: Acne Breakdown Rows

    /// Per-type comparison rows for the "Acne by Type" table.
    var acneTypeRows: [AcneComparisonRow] {
        AcneType.allCases
            .filter { $0 != .unknown }
            .map { type in
                AcneComparisonRow(
                    label: type.displayName,
                    valueA: recordA.acneCount(for: type),
                    valueB: recordB.acneCount(for: type)
                )
            }
    }

    /// Per-area comparison rows for the "Acne by Area" table.
    var acneAreaRows: [AcneComparisonRow] {
        ScanRecord.FaceArea.allCases.map { area in
            AcneComparisonRow(
                label: area.rawValue,
                valueA: recordA.acneCount(for: area),
                valueB: recordB.acneCount(for: area)
            )
        }
    }

    // MARK: - Actions

    // Date selection interaction was removed, so candidates/select methods are no longer needed.

    // MARK: - Static Formatters

    static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM"
        f.locale = Locale(identifier: "en_US")
        return f
    }()
}

// MARK: - AcneBreakdownMode

enum AcneBreakdownMode: String, CaseIterable, Identifiable {
    case byType = "type"
    case byArea = "area"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .byType: return "Acne by Type"
        case .byArea: return "Acne by Area"
        }
    }
}

// MARK: - AcneComparisonRow (lightweight presentation model)

struct AcneComparisonRow: Identifiable {
    let label: String
    let valueA: Int
    let valueB: Int

    var id: String { label }
    var delta: Int { valueB - valueA }
}
