import SwiftUI

enum SkincareRoute: Hashable {
    case add
    case pending
    case matched
    case manageActive
    case edit(SkincareProduct)
}

struct SkincareView: View {
    @ObservedObject var viewModel: SkincareViewModel
    let ingredientRepository: CosingIngredientRepository
    let acneRepository: AcneIngredientRepository
    let onDismiss: () -> Void

    @State private var navPath = NavigationPath()
    @State private var selectedRecommendation: SkincareIngredientRecommendation?

    var body: some View {
        NavigationStack(path: $navPath) {
            Group {
                if viewModel.products.isEmpty {
                    EmptySkincareView {
                        navPath.append(SkincareRoute.add)
                    }
                } else {
                    contentView
                }
            }
            .background(AppColor.backgroundPrimary)
            .navigationDestination(for: SkincareRoute.self) { route in
                switch route {
                case .add:
                    AddSkincareView(
                        skincareViewModel: viewModel,
                        ingredientRepository: ingredientRepository,
                        acneRepository: acneRepository,
                        onSave: {
                            navPath.removeLast()
                            navPath.append(SkincareRoute.pending)
                        }
                    )
                case .pending:
                    PendingSkincareListView(
                        viewModel: viewModel,
                        ingredientRepository: ingredientRepository,
                        acneRepository: acneRepository,
                        navPath: $navPath
                    )
                case .matched:
                    MatchedResultView(
                        viewModel: viewModel,
                        acneRepository: acneRepository,
                        navPath: $navPath
                    )
                case .manageActive:
                    ManageSkincareListView(
                        viewModel: viewModel,
                        ingredientRepository: ingredientRepository,
                        acneRepository: acneRepository,
                        navPath: $navPath
                    )
                case .edit(let product):
                    AddSkincareView(
                        skincareViewModel: viewModel,
                        ingredientRepository: ingredientRepository,
                        acneRepository: acneRepository,
                        editingProduct: product,
                        onSave: {
                            navPath.removeLast()
                        }
                    )
                }
            }
            .sheet(item: $selectedRecommendation) { rec in
                IngredientDetailView(recommendation: rec)
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    


    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                
                // Match Ingredient Section (SVG 08)
                if viewModel.hasScanned {
                    matchedSection
                        .padding(.bottom, AppSpacing.sm)
                }
                
                // Skincare List Section
                let activeProducts = viewModel.products.filter { $0.isUsedCurrently }
                let inactiveProducts = viewModel.products.filter { !$0.isUsedCurrently }
                
                if !activeProducts.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Your Current Skincare")
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColor.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                navPath.append(SkincareRoute.manageActive)
                            }) {
                                HStack(spacing: 2) {
                                    Text("See details")
                                    Image(systemName: "chevron.right")
                                }
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.accentPrimary)
                            }
                        }
                        
                        ForEach(activeProducts) { product in
                            NavigationLink(
                                destination: SkincareDetailView(
                                    skincareViewModel: viewModel,
                                    ingredientRepository: ingredientRepository,
                                    acneRepository: acneRepository,
                                    product: product
                                )
                            ) {
                                SkincareCard(
                                    product: product,
                                    recommendationsCount: viewModel.getRecommendations(for: product).count,
                                    onTap: {}
                                )
                            }
                        }
                    }
                }
                
                if !inactiveProducts.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Riwayat Produk Lain (\(inactiveProducts.count))")
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColor.textSecondary)
                        
                        ForEach(inactiveProducts) { product in
                            NavigationLink(
                                destination: SkincareDetailView(
                                    skincareViewModel: viewModel,
                                    ingredientRepository: ingredientRepository,
                                    acneRepository: acneRepository,
                                    product: product
                                )
                            ) {
                                SkincareCard(
                                    product: product,
                                    recommendationsCount: viewModel.getRecommendations(for: product).count,
                                    onTap: {}
                                )
                            }
                        }
                    }
                    .padding(.top, AppSpacing.sm)
                }
            }
            .padding(AppSpacing.md)
        }
        .navigationTitle("Skincare")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    navPath.append(SkincareRoute.add)
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.accentPrimary)
                }
            }
        }
    }

    /// Section "Match Ingredient" — ingredient unik dari semua produk yang
    /// cocok dengan tipe jerawat aktif user.
    private var matchedSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Match Ingredient")
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColor.textPrimary)

            Text("Kami merekomendasikan bahan yang sesuai dengan tipe jerawat dan kondisi kulit Anda.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)

            if viewModel.uniqueMatchedRecommendations.isEmpty {
                AppCard {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AppColor.textSecondary)
                        Text("Belum ada bahan yang cocok. Tambahkan produk untuk melihat rekomendasinya.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            } else {
                ForEach(viewModel.uniqueMatchedRecommendations) { match in
                    RecommendationCard(match: match) {
                        selectedRecommendation = match.recommendation
                    }
                }
            }
        }
    }
}

#Preview {
    let historyStore = ScanHistoryStore()
    let acneProfileProvider = AcneProfileProvider(historyStore: historyStore)
    let skincareRepository = SkincareProductRepository()
    let acneRepository = AcneIngredientRepository()
    let cosingRepository = CosingIngredientRepository()
    
    let viewModel = SkincareViewModel(
        skincareRepository: skincareRepository,
        acneRepository: acneRepository,
        acneProfileProvider: acneProfileProvider
    )
    
    return SkincareView(
        viewModel: viewModel,
        ingredientRepository: cosingRepository,
        acneRepository: acneRepository,
        onDismiss: {}
    )
}
