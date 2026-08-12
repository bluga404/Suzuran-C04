import SwiftUI

/// History tab — displays all past scans in a 3-column grid grouped by month.
/// Native iOS NavigationStack with large title and toolbar compare buttons.
struct HistoryView: View {
    @ObservedObject private var viewModel: HistoryViewModel

    struct ComparePayload: Identifiable, Hashable {
        let id = UUID()
        let recordA: ScanRecord
        let recordB: ScanRecord
    }

    @State private var activePayload: ComparePayload? = nil
    @State private var detailScanID: UUID?

    init(viewModel: HistoryViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: - Color Tokens & Grid Setup

    /// Card dimensions & spacing per specification
    private let cardWidth: CGFloat = 118
    private let cardHeight: CGFloat = 170
    private let gridSpacing: CGFloat = 8

    /// Color tokens
    private let borderNormal = Color(red: 0.87059, green: 0.87059, blue: 0.88235)      // #DEDEE1 100%
    private let borderSelected = Color(red: 0.33725, green: 0.28627, blue: 0.67451)    // #5649AC 100%
    private let dateBannerNormal = Color.black.opacity(0.50)                           // #000000 50%
    private let dateBannerSelected = Color(red: 0.61961, green: 0.58824, blue: 0.81176).opacity(0.70) // #9E96CF 70%
    private let purpleAccent = Color(red: 0.33725, green: 0.28627, blue: 0.67451)      // #5649AC

    private var columns: [GridItem] {
        [
            GridItem(.fixed(cardWidth), spacing: gridSpacing),
            GridItem(.fixed(cardWidth), spacing: gridSpacing),
            GridItem(.fixed(cardWidth), spacing: gridSpacing)
        ]
    }

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
            .navigationTitle(ScreenTitle.history.title)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                if viewModel.isCompareMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Compare (\(viewModel.selectedCount)/2)") {
                            if let (first, second) = viewModel.selectedPair {
                                activePayload = ComparePayload(recordA: first, recordB: second)
                            }
                        }
                        .disabled(!viewModel.canCompare)
                    }

                    // This is what keeps them as two separate glass pills
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation(.snappy(duration: 0.25)) {
                                viewModel.toggleCompareMode()
                            }
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Compare") {
                            withAnimation(.snappy(duration: 0.25)) {
                                viewModel.toggleCompareMode()
                            }
                        }
                    }
                }
            }
            .toolbar(.visible, for: .tabBar)
            .navigationDestination(item: $activePayload) { payload in
                HistoryFactory.makeCompareView(
                    recordA: payload.recordA,
                    recordB: payload.recordB,
                    allRecords: viewModel.records
                )
            }
            .navigationDestination(item: $detailScanID) { scanID in
                HomeFactory.makeDetailView(scanID: scanID, historyStore: viewModel.historyStore)
            }
        }
        .appScreenContainer()
    }

    // MARK: - Scrollable Grid Content

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                ForEach(viewModel.groupedRecords, id: \.key) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.key)
                            .font(Font.sectionTitle)
                            .foregroundStyle(.primary)
                            .padding(.top, 4)

                        LazyVGrid(columns: columns, spacing: gridSpacing) {
                            ForEach(section.records) { record in
                                gridItem(record)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 90) // Clear floating tab bar space
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    // MARK: - Grid Item (118 x 170 Photo Card)

    private func gridItem(_ record: ScanRecord) -> some View {
        let isSelected = viewModel.isSelected(record)

        return Button {
            if viewModel.isCompareMode {
                viewModel.toggleSelection(record)
            } else {
                detailScanID = record.id
            }
        } label: {
            ZStack(alignment: .bottom) {
                // Background image or fallback placeholder
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
                                    .font(.system(size: 34))
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipped()

                // Date banner at bottom of card frame
                HStack {
                    Spacer()
                    Text(dateFormatter.string(from: record.date))
                        .font(Font.metadata)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 6)
                .background(isSelected ? dateBannerSelected : dateBannerNormal)

                // Selection checkmark badge at top-right inside frame (during compare mode)
                if viewModel.isCompareMode {
                    VStack {
                        HStack {
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(purpleAccent)
                                    .background(Circle().fill(.white).padding(2))
                            } else {
                                Image(systemName: "circle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(8)
                        Spacer()
                    }
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                // 3pt inside stroke border
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? borderSelected : borderNormal,
                        lineWidth: 3
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
