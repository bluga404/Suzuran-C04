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
            .navigationTitle("Report")
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
                        series: viewModel.acneTypeSeriesData.filter { viewModel.isAcneTypeActive($0.id) },
                        dayLabels: viewModel.acneDayLabels,
                        selectedDay: viewModel.selectedAcnePointDay,
                        onSelectDay: viewModel.selectAcnePointDay
                    )

                    acneTypeChips
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

    private var acneTypeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.acneTypeSeriesData) { item in
                    let active = viewModel.isAcneTypeActive(item.id)

                    Button {
                        viewModel.toggleAcneTypeVisibility(item.id)
                    } label: {
                        AppChip(isActive: active, activeColor: item.acneType.color) {
                            Circle()
                                .fill(item.acneType.color)
                                .frame(width: 8, height: 8)

                            Text(item.acneType.displayName)
                                .font(Font.metadata)

                            Text("\(viewModel.acneTypeScoresByID[item.id] ?? item.latestScore)")
                                .font(Font.metadata.weight(.semibold))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }
}
