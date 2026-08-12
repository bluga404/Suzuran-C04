import SwiftUI

struct SkincareDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var skincareViewModel: SkincareViewModel
    let ingredientRepo: IngredientRepositoryProtocol
    let product: SkincareProduct

    @State private var isShowingEdit = false
    @State private var selectedRecommendation: SkincareIngredientRecommendation?

    /// Matches for this specific product, derived from the aggregate list.
    private var matches: [MatchedIngredient] {
        skincareViewModel.matchedIngredients(in: product)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                headerCard
                matchesSection
                ingredientsSection
                deleteButton
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.backgroundPrimary)
        .navigationTitle("Detail Skincare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { isShowingEdit = true }
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.accentPrimary)
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            if let latest = skincareViewModel.products.first(where: { $0.id == product.id }) {
                AddSkincareView(
                    skincareViewModel: skincareViewModel,
                    ingredientRepo: ingredientRepo,
                    makeViewModel: { SkincareFactory.makeAddSkincareViewModel(editing: latest) }
                )
            }
        }
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
