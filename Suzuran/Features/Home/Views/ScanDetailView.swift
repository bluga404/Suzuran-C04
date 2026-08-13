import SwiftUI

struct ScanDetailView: View {
    /// Owned by this view so the ViewModel persists across body re-evaluations
    /// (e.g., when presented inside a sheet).
    @ObservedObject private var viewModel: ScanDetailViewModel
    
    @State private var isShowingAboutAcne = false
    @State private var activeDetailPayload: PhotoDetailPayload? = nil
    @State private var lastSelectedRegion: FaceRegion? = nil

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

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
            if let lastSelectedRegion {
                viewModel.selectedRegion = lastSelectedRegion
            }
        }
        .onAppear {
            if let lastSelectedRegion {
                viewModel.selectedRegion = lastSelectedRegion
            }
        }
        .sheet(isPresented: $isShowingAboutAcne) {
            AboutAcneTypeView()
        }
        .navigationDestination(item: $activeDetailPayload) { payload in
            FullPhotoDetailView(payload: payload)
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
                            .font(Font.description)
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
                    withAnimation {
                        lastSelectedRegion = nil
                        viewModel.selectedRegion = nil
                    }
                }
                
                // Region Pills
                ForEach(FaceRegion.displayOrder, id: \.self) { region in
                    filterPill(title: region.englishDisplayName, isSelected: viewModel.selectedRegion == region) {
                        withAnimation {
                            lastSelectedRegion = region
                            viewModel.selectedRegion = region
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
    
    @ViewBuilder
    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            AppChip(isActive: isSelected, activeColor: AppColor.accentPrimary) {
                Text(title)
                    .font(Font.label)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func summaryHeader(data: ScanDetailData) -> some View {
        HStack(alignment: viewModel.selectedRegion == nil ? .top : .center, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if viewModel.selectedRegion == nil {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Skin Score")
                            .font(Font.graphLabel)
                        VStack(alignment: .leading, spacing: -2) {
                            Text(HomeScoreCalculator().scoreLabel(for: data.scan.overallScore))
                                .font(Font.system(size: 38, weight: .bold))
                                .foregroundStyle(.primary)
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(data.scan.overallScore)")
                                    .font(Font.bodyLarge)
                                    .foregroundStyle(.primary)
                                Text("/100")
                                    .font(Font.graphLabel)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: viewModel.selectedRegion == nil ? 2 : 4) {
                    Text("Most Detected Acne Type")
                        .font(Font.system(size: viewModel.selectedRegion == nil ? 12 : 14, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(viewModel.mostDetectedAcneType?.rawValue ?? "-")
                        .font(Font.system(size: viewModel.selectedRegion == nil ? 16 : 32, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.leading, AppSpacing.md)
            
            Spacer()
            
            // Image (tappable to view full photo preview)
            Button {
                let displayTitle = viewModel.selectedRegion?.englishDisplayName ?? "Face Capture"
                let dateStr = dateFormatter.string(from: data.scan.createdAt)
                activeDetailPayload = PhotoDetailPayload(
                    imageData: viewModel.renderedImageData,
                    uiImage: viewModel.image,
                    title: displayTitle,
                    dateText: dateStr
                )
            } label: {
                Group {
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .overlay(
                                FaceMaskScanVisualization(markers: viewModel.currentMarkers)
                            )
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
            }
            .buttonStyle(.plain)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .padding(.trailing, AppSpacing.md)
        }
    }
    
    @ViewBuilder
    private func totalAcneCard() -> some View {
        AppCard(
            backgroundColor: AppColor.surfacePurple,
            borderColor: .clear,
            borderWidth: 0
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Text("Total Acne")
                        .font(Font.bodyLarge)
                        .foregroundStyle(.primary)

                    Spacer()

                    VStack(spacing: 0) {
                        Text("\(viewModel.totalCountForSelected)")
                            .font(Font.description)
                            .foregroundStyle(AppColor.accentPrimary)
                        Text("Acne spots")
                            .font(Font.system(size: 10, weight: .medium))
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

                HStack(spacing: AppSpacing.xs) {
                    Text("Acne Type")
                        .font(Font.metadata)
                        .foregroundStyle(AppColor.accentPrimary)

                    Button {
                        isShowingAboutAcne = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(Font.system(size: 10))
                            .foregroundStyle(AppColor.accentPrimary)
                    }
                    .accessibilityLabel("Acne type information")

                    Spacer()
                }

                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.acneCountsForSelected, id: \.type) { item in
                        HStack {
                            Text(item.type.rawValue)
                                .font(Font.label)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(item.count)")
                                .font(Font.label)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}
