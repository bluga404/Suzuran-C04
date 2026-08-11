import SwiftUI

struct SkincareView: View {
    @ObservedObject var viewModel: SkincareViewModel
    let ingredientRepository: CosingIngredientRepository
    let acneRepository: AcneIngredientRepository
    let onDismiss: () -> Void

    @State private var isShowingAdd = false
    @State private var selectedRecommendation: SkincareIngredientRecommendation?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.products.isEmpty {
                    EmptySkincareView {
                        isShowingAdd = true
                    }
                } else {
                    contentView
                }
            }
            .background(AppColor.backgroundPrimary)
            .navigationDestination(isPresented: $isShowingAdd) {
                AddSkincareView(
                    skincareViewModel: viewModel,
                    ingredientRepository: ingredientRepository,
                    acneRepository: acneRepository
                )
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
                
                // Match Ingredient Section (SVG 08)
                matchedSection
                    .padding(.top, AppSpacing.sm)
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
