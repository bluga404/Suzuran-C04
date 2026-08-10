import SwiftUI

struct ScanDetailView: View {
    /// Owned by this view so the ViewModel persists across body re-evaluations
    /// (e.g., when presented inside a sheet).
    @StateObject private var viewModel: ScanDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ScanDetailViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    LoadingStateView(
                        title: "Memuat",
                        subtitle: "Mengambil data scan..."
                    )
                case .failed(let error):
                    ErrorStateView(
                        title: "Terjadi Kesalahan",
                        message: error.userMessage,
                        primaryActionTitle: "Coba Lagi",
                        onPrimaryAction: { Task { await viewModel.load() } }
                    )
                case .empty(let title, let message):
                    EmptyStateView(title: title, message: message)
                case .loaded(let data):
                    loadedContent(data: data)
                }
            }
            .appScreenContainer()
            .navigationTitle("Detail Scan")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func loadedContent(data: ScanDetailData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Acne type selector (horizontal pills for detected types)
                AcneTypeSelector(
                    types: data.detectedTypes,
                    selected: $viewModel.selectedAcneType
                )

                // Total count for selected type
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Total")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.totalCountForSelected)")
                        .font(AppTypography.title)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, AppSpacing.md)

                // Region breakdown in order: Forehead, Left Cheek, Right Cheek, Chin, Nose
                RegionBreakdownList(
                    regionCounts: viewModel.regionCountsForSelected
                )

                // Ingredient recommendations (expandable accordion cards)
                if !data.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Rekomendasi Bahan")
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, AppSpacing.md)

                        ForEach(data.recommendations) { rec in
                            DetailIngredientCard(recommendation: rec)
                        }
                    }
                }
            }
            .padding(.vertical, AppSpacing.md)
        }
    }
}
