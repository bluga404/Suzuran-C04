import SwiftUI

struct SkincareView: View {
    @ObservedObject var viewModel: SkincareViewModel
    let ingredientRepo: IngredientRepositoryProtocol
    /// Retained for `SkincareFactory.makeView(onDismiss:)` source compatibility.
    let onDismiss: () -> Void

    @State private var isShowingAdd = false
    @State private var isShowingMatchedList = false
    @State private var isShowingSkincareList = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.products.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .background(AppColor.backgroundPrimary)
            .sheet(isPresented: $isShowingAdd) {
                AddSkincareView(
                    skincareViewModel: viewModel,
                    ingredientRepo: ingredientRepo,
                    makeViewModel: { SkincareFactory.makeAddSkincareViewModel(editing: nil) }
                )
            }
            .navigationDestination(isPresented: $isShowingMatchedList) {
                MatchedIngredientListView(matched: viewModel.matchedIngredients)
            }
            .navigationDestination(isPresented: $isShowingSkincareList) {
                SkincareListView(viewModel: viewModel, ingredientRepo: ingredientRepo)
            }
            .alert(item: $viewModel.alert, content: makeAlert)
            .alert(
                "Terjadi Kesalahan",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear { viewModel.loadData() }
        }
    }

    // MARK: - Content

    private var productContent: some View {
        List {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                matchPreview
                
                HStack {
                    Text("Skincare Saat Ini")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    Button("See Detail") {
                        isShowingSkincareList = true
                    }
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.accentPrimary)
                    .frame(minHeight: 44)
                    .buttonStyle(.plain)
                }
            }
            .listRowInsets(EdgeInsets(top: AppSpacing.md, leading: AppSpacing.md, bottom: AppSpacing.sm, trailing: AppSpacing.md))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            let previewProducts = viewModel.products.prefix(3)
            ForEach(previewProducts) { product in
                SkincareCard(
                    product: product,
                    recommendationsCount: 0,
                    onEdit: nil
                )
                .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var matchPreview: some View {
        if !viewModel.activeAcneTypes.isEmpty {
            if viewModel.matchedIngredients.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Ingredient yang Cocok")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                    MatchedIngredientEmptyState()
                }
            } else {
                MatchedIngredientSection(
                    matched: viewModel.matchedIngredients,
                    onShowAll: { isShowingMatchedList = true }
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("Skincare")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("Your current skincare routine")
                            .font(AppTypography.body)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                
                VStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppColor.accentPrimary.opacity(0.05))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "bubbles.and.sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColor.accentPrimary)
                    }
                    
                    Text("Belum Ada Catatan Skincare")
                        .font(AppTypography.subtitle)
                        .foregroundStyle(AppColor.textPrimary)
                    
                    Text("Catat produk skincare yang Anda gunakan saat ini untuk menganalisis kesesuaian bahan aktifnya dengan kondisi jerawat Anda.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    Button(action: {
                        isShowingAdd = true
                    }) {
                        Text("Catat Skincare Pertama")
                            .font(AppTypography.bodyBold)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColor.accentPrimary)
                            .foregroundStyle(.white)
                            .cornerRadius(AppCornerRadius.md)
                    }
                    .padding(.top, AppSpacing.sm)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                
                // User Active Acne Profile Information
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack {
                            Image(systemName: "face.dashed")
                                .foregroundStyle(AppColor.accentPrimary)
                            Text("Tipe Jerawat Aktif Anda")
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColor.textPrimary)
                        }
                        
                        if viewModel.activeAcneTypes.isEmpty {
                            Text("Tidak ada jerawat aktif terdeteksi.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        } else {
                            HStack(spacing: AppSpacing.xs) {
                                ForEach(viewModel.activeAcneTypes) { type in
                                    Text(type.displayName)
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, AppSpacing.sm)
                                        .padding(.vertical, 4)
                                        .background(AppColor.accentPrimary.opacity(0.08))
                                        .foregroundStyle(AppColor.accentPrimary)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        Text("Berdasarkan hasil pemindaian wajah terakhir. Kandungan skincare Anda akan disesuaikan dengan tipe jerawat di atas.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                            .padding(.top, 4)
                    }
                }
                
                // Skincare List Section
                let activeProducts = viewModel.products.filter { $0.isUsedCurrently }
                let inactiveProducts = viewModel.products.filter { !$0.isUsedCurrently }
                
                if !activeProducts.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Sedang Digunakan (\(activeProducts.count))")
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(AppColor.textPrimary)
                        
                        ForEach(activeProducts) { product in
                            NavigationLink(
                                destination: SkincareDetailView(
                                    skincareViewModel: viewModel,
                                    ingredientRepository: ingredientRepository,
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
        .navigationTitle("Catatan Skincare")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isShowingAdd = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.accentPrimary)
                }
            }
        }
    }
}
