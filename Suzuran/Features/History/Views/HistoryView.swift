import SwiftUI

/// History tab — shows all past scans in a grid grouped by month.
/// Supports a compare mode where the user selects exactly 2 scans to compare.
struct HistoryView: View {
    @ObservedObject private var viewModel: HistoryViewModel

    @State private var showCompare = false

    init(viewModel: HistoryViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.xs), count: 3)
    private let comparePurple = Color(red: 0.506, green: 0.510, blue: 1.0) // #8182FF

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.records.isEmpty {
                    ContentUnavailableView(
                        "Belum Ada Riwayat",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Mulai scan wajah untuk melihat riwayat di sini.")
                    )
                } else {
                    scrollContent
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    compareButton
                }
            }
            .fullScreenCover(isPresented: $showCompare) {
                if let (first, second) = viewModel.selectedPair {
                    CompareView(
                        recordA: first,
                        recordB: second,
                        onDismiss: { showCompare = false }
                    )
                }
            }
        }
    }

    // MARK: - Compare Button

    private var compareButton: some View {
        Button {
            if !viewModel.isCompareMode {
                viewModel.toggleCompareMode()
            } else if viewModel.canCompare {
                showCompare = true
            }
        } label: {
            if viewModel.isCompareMode {
                Text("Compare (\(viewModel.selectedCount)/2)")
                    .font(.system(size: 14, weight: .semibold))
            } else {
                Text("Compare")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .tint(comparePurple)
        .disabled(viewModel.isCompareMode && !viewModel.canCompare)
        .buttonStyle(.glassProminent)
    }

    // MARK: - Grid Content

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                ForEach(viewModel.groupedRecords, id: \.key) { section in
                    Section {
                        LazyVGrid(columns: columns, spacing: AppSpacing.xs) {
                            ForEach(section.records) { record in
                                gridItem(record)
                            }
                        }
                    } header: {
                        Text(section.key)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding(.top, AppSpacing.xs)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    // MARK: - Grid Item

    private func gridItem(_ record: ScanRecord) -> some View {
        Button {
            if viewModel.isCompareMode {
                viewModel.toggleSelection(record)
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    // Thumbnail
                    Group {
                        if let data = record.frontImageData,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Rectangle()
                                .fill(Color(.secondarySystemGroupedBackground))
                                .overlay(
                                    Image(systemName: "person.crop.rectangle")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.secondary)
                                )
                        }
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                            .stroke(
                                viewModel.isSelected(record) ? comparePurple : Color(.separator),
                                lineWidth: viewModel.isSelected(record) ? 2.5 : 0.5
                            )
                    )

                    // Date label
                    Text(dateFormatter.string(from: record.date))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Selection checkmark badge (compare mode only)
                if viewModel.isCompareMode {
                    Image(systemName: viewModel.isSelected(record) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(viewModel.isSelected(record) ? comparePurple : Color(.systemGray3))
                        .background(Circle().fill(Color(.systemBackground)).padding(2))
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
