import SwiftUI

struct ScanDetailView: View {
    /// Owned by this view so the ViewModel persists across body re-evaluations
    /// (e.g., when presented inside a sheet).
    @ObservedObject private var viewModel: ScanDetailViewModel

    init(viewModel: ScanDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
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
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: ObjectIdentifier(viewModel)) {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func loadedContent(data: ScanDetailData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                
                // Horizontal Filter Pills
                filterPillsView()
                
                // Summary Header
                summaryHeader(data: data)
                
                // Total Acne Card
                totalAcneCard()

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
    
    @ViewBuilder
    private func filterPillsView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                // "All" Pill
                filterPill(title: "All", isSelected: viewModel.selectedRegion == nil) {
                    withAnimation { viewModel.selectedRegion = nil }
                }
                
                // Region Pills
                ForEach(FaceRegion.displayOrder, id: \.self) { region in
                    filterPill(title: region.rawValue, isSelected: viewModel.selectedRegion == region) {
                        withAnimation { viewModel.selectedRegion = region }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
    
    @ViewBuilder
    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("AvenirNext-DemiBold", size: 14))
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Color.white : .primary)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? AppColor.accentPrimary : Color(uiColor: .systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : AppColor.borderSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func summaryHeader(data: ScanDetailData) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if viewModel.selectedRegion == nil {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Skin Score")
                            .font(.custom("AvenirNext-Medium", size: 12))
                            .foregroundStyle(.primary)
                        VStack(alignment: .leading, spacing: -2) {
                            Text(HomeScoreCalculator().scoreLabel(for: data.scan.overallScore))
                                .font(.custom("AvenirNext-Bold", size: 38))
                                .foregroundStyle(.primary)
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(data.scan.overallScore)")
                                    .font(.custom("AvenirNext-Bold", size: 18))
                                    .foregroundStyle(.primary)
                                Text("/100")
                                    .font(.custom("AvenirNext-Medium", size: 12))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Most Detected Acne Type")
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(.primary)
                    Text(viewModel.mostDetectedAcneType?.rawValue ?? "-")
                        .font(.custom("AvenirNext-Bold", size: 16))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.leading, AppSpacing.md)
            
            Spacer()
            
            // Image
            Group {
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color(uiColor: .systemGray6))
                        .overlay(
                            Image(systemName: "face.dashed")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 140, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColor.borderSubtle, lineWidth: 2)
            )
            .padding(.trailing, AppSpacing.md)
        }
    }
    
    @ViewBuilder
    private func totalAcneCard() -> some View {
        AppCard(padding: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                HStack {
                    Text("Total Acne")
                        .font(.custom("AvenirNext-DemiBold", size: 18))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    VStack(spacing: 0) {
                        Text("\(viewModel.totalCountForSelected)")
                            .font(.custom("AvenirNext-DemiBold", size: 16))
                            .foregroundStyle(AppColor.accentPrimary)
                        Text("Acne spots")
                            .font(.custom("AvenirNext-Medium", size: 10))
                            .foregroundStyle(AppColor.accentPrimary.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColor.accentPrimary.opacity(0.15))
                    )
                }
                
                Divider()
                
                // List of Acne Types
                HStack {
                    Text("Acne Type")
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundStyle(.secondary)
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.acneCountsForSelected, id: \.type) { item in
                        HStack {
                            Text(item.type.rawValue)
                                .font(.custom("AvenirNext-Regular", size: 15))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(item.count)")
                                .font(.custom("AvenirNext-DemiBold", size: 15))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}
