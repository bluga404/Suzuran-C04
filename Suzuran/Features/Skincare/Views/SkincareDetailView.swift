import SwiftUI

struct SkincareDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var skincareViewModel: SkincareViewModel
    let ingredientRepository: SkincareIngredientRepository
    let product: SkincareProduct

    @State private var isShowingEdit = false
    @State private var selectedRecommendation: SkincareIngredientRecommendation?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header card
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text(product.category)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, 4)
                                .background(AppColor.accentPrimary.opacity(0.1))
                                .foregroundStyle(AppColor.accentPrimary)
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            // Usage badge
                            Text(product.isUsedCurrently ? "Sedang Digunakan" : "Tidak Digunakan")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(product.isUsedCurrently ? AppColor.accentPrimary : AppColor.textSecondary)
                        }
                        
                        Text(product.name)
                            .font(AppTypography.title)
                            .foregroundStyle(AppColor.textPrimary)
                        
                        Text("Merek: \(product.brand)")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                
                // Matches section
                let recommendations = skincareViewModel.getRecommendations(for: product)
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Kesesuaian dengan Kulit Anda")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                    
                    if recommendations.isEmpty {
                        AppCard {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppColor.textSecondary)
                                
                                Text("Tidak ada kandungan aktif khusus untuk tipe jerawat Anda saat ini (\(skincareViewModel.activeAcneTypes.map { $0.displayName }.joined(separator: ", "))).")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    } else {
                        ForEach(recommendations) { match in
                            RecommendationCard(match: match) {
                                selectedRecommendation = match.recommendation
                            }
                        }
                    }
                }
                
                // Full ingredients section
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Semua Komposisi (\(product.ingredients.count))")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                    
                    if product.ingredients.isEmpty {
                        Text("Tidak ada informasi komposisi.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    } else {
                        // Display chips
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 200), spacing: 8)], spacing: 8) {
                            ForEach(product.ingredients, id: \.self) { ingredient in
                                let rec = ingredientRepository.getRecommendation(for: ingredient)
                                let isMatched = rec != nil
                                
                                Button(action: {
                                    if let rec = rec {
                                        selectedRecommendation = rec
                                    }
                                }) {
                                    IngredientChip(name: ingredient, isMatched: isMatched)
                                }
                                .disabled(!isMatched)
                            }
                        }
                    }
                }
                
                // Delete Action button at bottom
                Button(action: deleteProduct) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Hapus Produk Ini")
                            .font(AppTypography.bodyBold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColor.accentDanger.opacity(0.08))
                    .foregroundStyle(AppColor.accentDanger)
                    .cornerRadius(AppCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.md)
                            .stroke(AppColor.accentDanger.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.top, AppSpacing.lg)
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary)
        .navigationTitle("Detail Skincare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isShowingEdit = true
                }
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColor.accentPrimary)
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            if let latestProduct = skincareViewModel.products.first(where: { $0.id == product.id }) {
                EditSkincareView(
                    skincareViewModel: skincareViewModel,
                    ingredientRepository: ingredientRepository,
                    product: latestProduct
                )
            }
        }
        .sheet(item: $selectedRecommendation) { rec in
            IngredientDetailView(recommendation: rec)
        }
    }

    private func deleteProduct() {
        skincareViewModel.deleteProduct(id: product.id)
        dismiss()
    }
}
