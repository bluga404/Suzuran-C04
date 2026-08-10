import SwiftUI

// MARK: - UUID + Identifiable (needed for .sheet(item:))
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

/// Root Home screen that observes HomeSummaryViewModel and renders
/// sub-components based on the current LoadableState and HomeSummaryState.
/// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 13.1, 13.2, 13.5, 13.6, 13.7
struct HomeView: View {
    @ObservedObject var viewModel: HomeSummaryViewModel
    let historyStore: ScanHistoryStore?
    @Environment(\.switchToTab) private var switchToTab
    @State private var detailScanID: UUID?
    @State private var isShowingScanSheet = false

    init(viewModel: HomeSummaryViewModel, historyStore: ScanHistoryStore? = nil) {
        self.viewModel = viewModel
        self.historyStore = historyStore
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingStateView(
                    title: "Memuat",
                    subtitle: "Mengambil data kulit kamu..."
                )
            case .failed(let error):
                ErrorStateView(
                    title: "Terjadi Kesalahan",
                    message: error.userMessage,
                    primaryActionTitle: "Coba Lagi",
                    onPrimaryAction: {
                        Task { await viewModel.load() }
                    }
                )
            case .empty(let title, let message):
                EmptyStateView(title: title, message: message)
            case .loaded(let summary):
                loadedContent(summary: summary)
            }
        }
        .appScreenContainer()
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func loadedContent(summary: HomeSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HomeHeader(
                    date: summary.date,
                    showCameraButton: summary.scanAvailability.hasFaceScan,
                    onScanTap: { isShowingScanSheet = true }
                )

                SkinScoreCard(
                    score: summary.skinScore,
                    state: summary.state,
                    onAction: {
                        if summary.state == .empty {
                            isShowingScanSheet = true
                        } else {
                            detailScanID = summary.latestScan?.id
                        }
                    }
                )
                .padding(.horizontal, AppSpacing.md)

                if summary.state != .empty {
                    MostDetectedSection(
                        acneType: summary.dominantAcne,
                        count: dominantCount(in: summary)
                    )

                    IngredientSection(
                        recommendations: summary.recommendations,
                        showEmptyState: summary.recommendations.isEmpty,
                        onTrackTap: { switchToTab(.skincare) }
                    )
                }
            }
            .padding(.vertical, AppSpacing.md)
        }
        .fullScreenCover(isPresented: $isShowingScanSheet) {
            FaceScanFactory.makeView(
                onScanSaved: { session, result in
                    let mapper = FaceScanToSkinScanMapper()
                    let skinScan = mapper.map(session: session)
                    HomeFactory.sharedScanRepository.save(skinScan)
                    historyStore?.save(result)
                },
                onDismiss: {
                    isShowingScanSheet = false
                    Task { await viewModel.load() }
                }
            )
        }
        .sheet(item: $detailScanID) { scanID in
            HomeFactory.makeDetailView(scanID: scanID)
        }
    }

    /// Returns the detection count of the dominant acne type from the latest scan, if available.
    private func dominantCount(in summary: HomeSummary) -> Int? {
        guard let dominant = summary.dominantAcne, let scan = summary.latestScan else { return nil }
        return scan.acneCounts[dominant]
    }
}
