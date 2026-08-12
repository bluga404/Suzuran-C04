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
    @State private var isShowingAboutAcne = false
    @State private var isShowingAboutSkinScore = false

    init(viewModel: HomeSummaryViewModel, historyStore: ScanHistoryStore? = nil) {
        self.viewModel = viewModel
        self.historyStore = historyStore
    }

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Summary")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let summary = loadedSummary, summary.scanAvailability.hasFaceScan {
                        Button(action: { isShowingScanSheet = true }) {
                            Image(systemName: "camera")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppColor.accentPrimary)
                        }
                        .accessibilityLabel("Start face scan")
                    }
                }
            }
        }
        .appScreenContainer()
        .task {
            await viewModel.load()
        }
    }

    private var loadedSummary: HomeSummary? {
        if case .loaded(let summary) = viewModel.state {
            return summary
        }
        return nil
    }

    @ViewBuilder
    private func loadedContent(summary: HomeSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Native title replaces HomeHeader's title, we just show date here
                Text(formattedDate(for: summary.date))
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.xs)

                SkinScoreCard(
                    score: summary.skinScore,
                    state: summary.state,
                    onAction: {
                        if summary.state == .empty {
                            isShowingScanSheet = true
                        } else {
                            detailScanID = summary.latestScan?.id
                        }
                    },
                    onInfoAction: { isShowingAboutSkinScore = true }
                )
                .padding(.horizontal, AppSpacing.md)

                if summary.state != .empty {
                    MostDetectedSection(
                        acneType: summary.dominantAcne,
                        count: dominantCount(in: summary),
                        onInfoTap: { isShowingAboutAcne = true }
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
        .navigationDestination(item: $detailScanID) { scanID in
            HomeFactory.makeDetailView(scanID: scanID, historyStore: historyStore)
        }
        .sheet(isPresented: $isShowingAboutAcne) {
            AboutAcneTypeView()
        }
        .sheet(isPresented: $isShowingAboutSkinScore) {
            AboutSkinScoreView()
        }
        .sheet(isPresented: $isShowingAboutAcne) {
            AboutAcneTypeView()
        }
        .sheet(isPresented: $isShowingAboutSkinScore) {
            AboutSkinScoreView()
        }
    }

    /// Returns the detection count of the dominant acne type from the latest scan, if available.
    private func dominantCount(in summary: HomeSummary) -> Int? {
        guard let dominant = summary.dominantAcne, let scan = summary.latestScan else { return nil }
        return scan.acneCounts[dominant]
    }

    private func formattedDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM, yyyy"
        return formatter.string(from: date)
    }
}
