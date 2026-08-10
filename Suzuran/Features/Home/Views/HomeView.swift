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
    @Environment(\.switchToTab) private var switchToTab
    @State private var detailScanID: UUID?
    @State private var isShowingScanSheet = false

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
                    DominantAcneSection(acneType: summary.dominantAcne)
                }

                if summary.state != .empty && summary.state != .faceOnly {
                    RecommendationSection(
                        recommendations: summary.recommendations,
                        showEmptyState: summary.recommendations.isEmpty
                    )
                    TrackSkincareButton(onTap: { switchToTab(.skincare) })
                }
            }
            .padding(.vertical, AppSpacing.md)
        }
        .fullScreenCover(isPresented: $isShowingScanSheet) {
            FaceScanFactory.makeView(
                onScanSaved: { session in
                    let mapper = FaceScanToSkinScanMapper()
                    let skinScan = mapper.map(session: session)
                    HomeFactory.sharedScanRepository.save(skinScan)
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
}
