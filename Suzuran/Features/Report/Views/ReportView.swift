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

                    if !viewModel.hasAnyData {
                        EmptyStateView(
                            title: "Belum ada riwayat scan",
                            message: "Lakukan scan wajah pertama untuk melihat perkembangan kulitmu di sini.",
                            actionTitle: nil,
                            onAction: nil
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        reportChartSection

                        ReportSummaryCardsView(
                            selectedMetric: viewModel.selectedMetric,
                            skinScoreSummary: viewModel.skinScoreSummary,
                            acneSummary: viewModel.mostDetectedAcneSummary,
                            insight: viewModel.insightSummary
                        )
                    }
                }
                .padding(AppSpacing.sm)
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
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var reportChartSection: some View {
        if viewModel.selectedMetric == .acneType {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if viewModel.acneTypeSeriesData.isEmpty {
                    EmptyStateView(
                        title: "Belum ada data jerawat",
                        message: "Riwayat scan yang tersimpan belum mencatat tipe jerawat untuk rentang ini.",
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
                    title: "Belum ada data score",
                    message: "Grafik score akan muncul setelah ada scan yang tersimpan.",
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
