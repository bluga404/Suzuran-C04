import SwiftUI

struct ReportView: View {
    @ObservedObject private var viewModel: ReportViewModel

    init(viewModel: ReportViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    LoadingStateView(
                        title: "Loading report",
                        subtitle: "Preparing your skin insights..."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .failed(let error):
                    ErrorStateView(
                        title: "Unable to load report",
                        message: error.userMessage,
                        primaryActionTitle: "Retry",
                        onPrimaryAction: {
                            Task { await viewModel.refreshSummary() }
                        }
                    )
                    .frame(maxWidth: .infinity)

                case .empty(let title, let message):
                    EmptyStateView(
                        title: title,
                        message: message,
                        actionTitle: nil,
                        onAction: nil
                    )
                    .frame(maxWidth: .infinity)

                case .loaded:
                    loadedContent
                }
            }
            .navigationTitle("Summary")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
        .appScreenContainer()
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var loadedContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                ReportFilterHeaderView(
                    selectedMetric: viewModel.selectedMetric,
                    selectedRange: viewModel.selectedRange,
                    onMetricChanged: viewModel.setMetric,
                    onRangeChanged: viewModel.setRange
                )

                reportChartSection

                ReportSummaryCardsView(
                    selectedMetric: viewModel.selectedMetric,
                    skinScoreSummary: viewModel.skinScoreSummary,
                    acneSummary: viewModel.mostDetectedAcneSummary,
                    insight: viewModel.insightSummary
                )
            }
            .padding(AppSpacing.sm)
        }
    }

    @ViewBuilder
    private var reportChartSection: some View {
        if viewModel.selectedMetric == .acneType {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if viewModel.acneTypeSeriesData.isEmpty {
                    EmptyStateView(
                        title: "No acne data",
                        message: "No acne breakdown is available for this time range yet.",
                        actionTitle: nil,
                        onAction: nil
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    ReportAcneTypeChartView(
                        points: viewModel.visibleAcneChartPoints,
                        dayLabels: viewModel.acneDayLabels,
                        selectedDay: viewModel.selectedAcnePointDay,
                        onSelectDay: viewModel.selectAcnePointDay
                    )

                    ReportAcneTypeChipsView(
                        series: viewModel.acneTypeSeriesData,
                        isActive: viewModel.isAcneTypeActive,
                        scoresByAcneTypeID: viewModel.acneTypeScoresByID,
                        onToggle: viewModel.toggleAcneTypeVisibility
                    )
                }
            }
        } else {
            if viewModel.skinScoreData.isEmpty {
                EmptyStateView(
                    title: "No score data",
                    message: "Your skin score chart will appear once a scan is saved.",
                    actionTitle: nil,
                    onAction: nil
                )
                .frame(maxWidth: .infinity)
            } else {
                ReportSkinScoreChartView(data: viewModel.skinScoreData)
            }
        }
    }
}
