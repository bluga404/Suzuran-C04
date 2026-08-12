import SwiftUI

struct SkincareDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var skincareViewModel: SkincareViewModel
    let ingredientRepository: CosingIngredientRepository
    let acneRepository: AcneIngredientRepository
    let product: SkincareProduct

    @State private var selectedRecommendation: SkincareIngredientRecommendation?

    /// Matches for this specific product, derived from the aggregate list.
    private var matches: [MatchedIngredient] {
        skincareViewModel.matchedIngredients(in: product)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header card
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text(product.category.displayName)
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
                                let rec = acneRepository.getRecommendation(for: ingredient.normalizedName)
                                let isMatched = rec != nil
                                
                                Button(action: {
                                    if let rec = rec {
                                        selectedRecommendation = rec
                                    }
                                }) {
                                    IngredientChip(name: ingredient.name, isMatched: isMatched)
                                }
                                .disabled(!isMatched)
                            }
                        }
                    }
                }
                
                // Action buttons at bottom
                VStack(spacing: AppSpacing.sm) {
                    if let latestProduct = skincareViewModel.products.first(where: { $0.id == product.id }) {
                        NavigationLink(destination: EditSkincareView(
                            skincareViewModel: skincareViewModel,
                            ingredientRepository: ingredientRepository,
                            acneRepository: acneRepository,
                            product: latestProduct
                        )) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Skincare")
                                    .font(AppTypography.bodyBold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColor.surfacePrimary)
                            .foregroundStyle(AppColor.accentPrimary)
                            .cornerRadius(AppCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                    .stroke(AppColor.accentPrimary, lineWidth: 1)
                            )
                        }
                    }
                    
                    Button(action: deleteProduct) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Hapus Produk Ini")
                                .font(AppTypography.bodyBold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColor.accentDanger.opacity(0.08))
                        .foregroundStyle(AppColor.accentDanger)
                        .cornerRadius(AppCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                .stroke(AppColor.accentDanger.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.top, AppSpacing.md)
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary)
        .navigationTitle("Detail Skincare")
        .navigationBarTitleDisplayMode(.inline)
        // Toolbar Edit button removed in favor of prominent bottom button
        .sheet(item: $selectedRecommendation) { rec in
            IngredientDetailView(recommendation: rec)
        }
        .alert(item: $skincareViewModel.alert, content: makeDeleteAlert)
        .onChange(of: skincareViewModel.products) { _, products in
            // Pop back to Home once this product has been deleted (Req 17.3, 17.4).
            if !products.contains(where: { $0.id == product.id }) {
                dismiss()
            }
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: product.category.iconSystemName)
                            .font(.system(size: 10))
                        Text(product.category.displayName)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background(AppColor.accentPrimary.opacity(0.1))
                    .foregroundStyle(AppColor.accentPrimary)
                    .clipShape(Capsule())

                    Spacer()
                }

                Text(product.name)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Merek: \(product.brand)")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Kesesuaian dengan Kulit Anda")
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColor.textPrimary)

            if matches.isEmpty {
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
                ForEach(matches) { matched in
                    Button {
                        selectedRecommendation = matched.recommendation
                    } label: {
                        RecommendationCard(matched: matched)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Semua Komposisi (\(product.ingredients.count))")
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColor.textPrimary)

            if product.ingredients.isEmpty {
                Text("Tidak ada informasi komposisi.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 200), spacing: 8)], spacing: 8) {
                    ForEach(product.ingredients, id: \.id) { ingredient in
                        let matched = skincareViewModel.matched(for: ingredient)
                        Button(action: {
                            if let matched { selectedRecommendation = matched.recommendation }
                        }) {
                            IngredientChip(name: ingredient.name, isMatched: matched != nil)
                        }
                        .disabled(matched == nil)
                    }
                }
            }
        }
    }

    private var deleteButton: some View {
        Button(action: { skincareViewModel.requestDelete(product) }) {
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

    // MARK: - Delete alert (Req 17)

    private func makeDeleteAlert(_ alert: SkincareAlert) -> Alert {
        switch alert {
        case .deleteProduct(let target):
            return Alert(
                title: Text("Hapus Produk"),
                message: Text("Hapus \"\(target.name)\" dari catatan skincare Anda?"),
                primaryButton: .destructive(Text("Hapus")) { skincareViewModel.confirmDelete(target) },
                secondaryButton: .cancel(Text("Batal"))
            )
        case .deleteLastProduct(let target):
            return Alert(
                title: Text("Hapus Produk Terakhir"),
                message: Text("\"\(target.name)\" adalah produk terakhir. Menghapusnya akan mengembalikan halaman ke kondisi kosong."),
                primaryButton: .destructive(Text("Hapus")) { skincareViewModel.confirmDelete(target) },
                secondaryButton: .cancel(Text("Batal"))
            )
        case .saveEmpty:
            return Alert(title: Text(""))
        }
    }
}
