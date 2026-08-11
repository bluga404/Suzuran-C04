import SwiftUI

struct ReportView: View {
    @ObservedObject private var viewModel: ReportViewModel
    let onDismiss: () -> Void

    init(viewModel: ReportViewModel, onDismiss: @escaping () -> Void = {}) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
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
                        comparison: viewModel.comparisonSummary,
                        insight: viewModel.insightSummary
                    )
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Report")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EmptyView()
                }
            }
        }
        .appScreenContainer()
        .task {
            viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var reportChartSection: some View {
        if viewModel.selectedMetric == .acneType {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ReportAcneTypeChartView(
                    points: viewModel.visibleAcneChartPoints,
                    dayLabels: viewModel.acneDayLabels,
                    selectedDay: viewModel.selectedAcnePointDay,
                    onSelectDay: viewModel.selectAcnePointDay
                )
                    .frame(height: 220)

                ReportAcneTypeChipsView(
                    series: viewModel.acneTypeSeriesData,
                    isActive: viewModel.isAcneTypeActive,
                    scoresByAcneTypeID: viewModel.acneTypeScoresByID,
                    onToggle: viewModel.toggleAcneTypeVisibility
                )
            }
        } else {
            ReportSkinScoreChartView(data: viewModel.skinScoreData)
                .frame(height: 180)
        }
    }
}
