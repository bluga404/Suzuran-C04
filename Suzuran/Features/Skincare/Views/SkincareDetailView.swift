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
        .navigationTitle("Skincare Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { isShowingEdit = true }
                    .font(Font.description)
                    .foregroundStyle(AppColor.accentPrimary)
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            if let latest = skincareViewModel.products.first(where: { $0.id == product.id }) {
                NavigationStack {
                    AddSkincareView(
                        skincareViewModel: skincareViewModel,
                        ingredientRepo: ingredientRepo,
                        makeViewModel: { SkincareFactory.makeAddSkincareViewModel(editing: latest) }
                    )
                }
            }
        }
        .sheet(item: $selectedRecommendation) { rec in
            IngredientDetailView(
                recommendation: rec
            )
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

                    Text(product.isUsedCurrently ? "Currently Used" : "Not Used")
                        .font(Font.metadata)
                        .fontWeight(.semibold)
                        .foregroundStyle(product.isUsedCurrently ? AppColor.accentPrimary : AppColor.textSecondary)
                }

                Text(product.name)
                    .font(Font.screenTitle)
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
    }

    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Skin Compatibility")
                .font(Font.description)
                .foregroundStyle(AppColor.textPrimary)

            if matches.isEmpty {
                AppCard {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColor.textSecondary)

                        Text("No active ingredients found for your current acne types (\(skincareViewModel.activeAcneTypes.map { $0.displayName }.joined(separator: ", "))).")
                            .font(Font.metadata)
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
            Text("All Ingredients (\(product.ingredients.count))")
                .font(Font.description)
                .foregroundStyle(AppColor.textPrimary)

            if product.ingredients.isEmpty {
                Text("No ingredient information available.")
                    .font(Font.description)
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
                Text("Delete This Product")
                    .font(Font.description)
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
                title: Text("Delete Product"),
                message: Text("Remove \"\(target.name)\" from your skincare record?"),
                primaryButton: .destructive(Text("Delete")) { skincareViewModel.confirmDelete(target) },
                secondaryButton: .cancel(Text("Cancel"))
            )
        case .deleteLastProduct(let target):
            return Alert(
                title: Text("Delete Last Product"),
                message: Text("\"\(target.name)\" is your last product. Removing it will return the page to an empty state."),
                primaryButton: .destructive(Text("Delete")) { skincareViewModel.confirmDelete(target) },
                secondaryButton: .cancel(Text("Cancel"))
            )
        case .saveEmpty:
            return Alert(title: Text(""))
        }
    }
}
