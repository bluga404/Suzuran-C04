import SwiftUI

/// Add/Edit form built with native `Form` sections, following the reference on
/// `feature/integrate-ingredients`: kategori produk → nama produk → ingredients
/// → save. Kategori memakai `Picker` gaya `.menu` bawaan iOS.
struct AddSkincareView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var skincareViewModel: SkincareViewModel
    @StateObject private var viewModel: AddSkincareViewModel

    @State private var isShowingSearch = false
    @State private var isShowingScanner = false
    @State private var isConfirmingClearAll = false
    @State private var manualCandidate = ""

    private let ingredientRepo: IngredientRepositoryProtocol

    init(
        skincareViewModel: SkincareViewModel,
        ingredientRepo: IngredientRepositoryProtocol,
        makeViewModel: @escaping @MainActor () -> AddSkincareViewModel
    ) {
        self.skincareViewModel = skincareViewModel
        self.ingredientRepo = ingredientRepo
        self._viewModel = StateObject(wrappedValue: makeViewModel())
    }

    var body: some View {
        Form {
            Section("Product Information") {
                Picker("Select Category", selection: $viewModel.draft.category) {
                    Text("Select Category").tag(Optional<SkincareCategory>.none)
                    ForEach(SkincareCategory.allCases) { category in
                        Text(category.displayName).tag(Optional(category))
                    }
                }
                .pickerStyle(.menu)
                .font(Font.description)

                TextField("Product Name", text: $viewModel.draft.name)
                    .font(Font.description)
                    .textInputAutocapitalization(.words)
            }

            ingredientSection
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.backgroundPrimary)
        .navigationTitle(viewModel.isEditing ? "Edit Skincare" : "Add Skincare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .font(Font.description)
                    .foregroundStyle(AppColor.accentPrimary)
                    .frame(minHeight: 44)
            }
        }
        .safeAreaInset(edge: .bottom) {
            AppButton(
                title: viewModel.isEditing ? "Save Changes" : "Save Skincare",
                isLoading: viewModel.isSaving
            ) {
                viewModel.save(into: skincareViewModel)
            }
            .disabled(!viewModel.isFormValid)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(.regularMaterial)
        }
        .disabled(viewModel.alert != nil)
        .sheet(isPresented: $isShowingSearch) {
            IngredientSearchView(repository: ingredientRepo) { name in
                viewModel.addIngredient(name)
            }
        }
        .fullScreenCover(isPresented: $isShowingScanner) {
            IngredientScanView(viewModel: viewModel)
        }
        .alert(
            "Remove all ingredients?",
            isPresented: $isConfirmingClearAll
        ) {
            Button("Remove All", role: .destructive) { viewModel.confirmClearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All ingredient in this draft will be removed. Name and category will be kept.")
        }
        .alert(item: $viewModel.alert, content: makeSaveEmptyAlert)
        .alert(
            "Incomplete Data",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved { dismiss() }
        }
    }

    // MARK: - Ingredients section

    @ViewBuilder
    private var ingredientSection: some View {
        Section {
            Button {
                isShowingScanner = true
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(Font.description)
                        .foregroundStyle(AppColor.accentPrimary)
                        .frame(width: 24)

                    Text("Scan product composition")
                        .font(Font.description)
                        .foregroundStyle(AppColor.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }

            Button {
                isShowingSearch = true
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(Font.description)
                        .foregroundStyle(AppColor.accentPrimary)
                        .frame(width: 24)

                    Text("Search ingredient manually")
                        .font(Font.description)
                        .foregroundStyle(AppColor.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            HStack {
                Text("INGREDIENT")
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .font(.footnote)

                Spacer()

                if !viewModel.draft.ingredients.isEmpty {
                    Button("Remove All") { isConfirmingClearAll = true }
                        .font(Font.metadata)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.accentDanger)
                        .textCase(nil)
                }
            }
        }

        if !viewModel.scannedIngredients.isEmpty {
            scannedReviewSection
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
        }

        Section {
            if viewModel.draft.ingredients.isEmpty {
                Text("Your skincare ingredients will appear here.")
                    .font(Font.description)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                ingredientChips
                    .padding(.vertical, AppSpacing.xxs)
            }
        }
    }

    /// OCR candidates stay in the Add screen for review and manual correction,
    /// matching mockup 04 rather than moving the user into a disconnected screen.
    private var scannedReviewSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Review Scan Results")
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Remove inaccurate candidates or add missed ingredients.")
                    .font(Font.metadata)
                    .foregroundStyle(AppColor.textSecondary)

                candidateChips
                manualCandidateField

                AppButton(title: "Use These Ingredients") {
                    viewModel.commitReview()
                }
            }
        }
    }

    private var candidateChips: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 120), spacing: AppSpacing.xs)],
            spacing: AppSpacing.xs
        ) {
            ForEach(viewModel.scannedIngredients, id: \.self) { candidate in
                IngredientChip(name: candidate, onDelete: {
                    viewModel.removeScannedIngredient(candidate)
                })
            }
        }
    }

    private var manualCandidateField: some View {
        HStack(spacing: AppSpacing.xs) {
            TextField("Add ingredient manually", text: $manualCandidate)
                .font(Font.description)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, AppSpacing.sm)
                .frame(minHeight: 44)
                .background(AppColor.backgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .stroke(AppColor.borderSubtle, lineWidth: 1)
                )
                .onSubmit(addManualCandidate)

            Button(action: addManualCandidate) {
                Image(systemName: "plus")
                    .font(Font.description)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.accentPrimary)
            .accessibilityLabel("Add ingredient manually")
        }
    }


    private var ingredientChips: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 120), spacing: AppSpacing.xs)],
            spacing: AppSpacing.xs
        ) {
            ForEach(viewModel.draft.ingredients) { ingredient in
                IngredientChip(name: ingredient.name, isMatched: viewModel.isMatched(ingredient)) {
                    viewModel.removeIngredient(ingredient)
                }
            }
        }
    }

    private func addManualCandidate() {
        viewModel.addScannedIngredient(manualCandidate)
        manualCandidate = ""
    }

    // MARK: - Save-empty alert

    private func makeSaveEmptyAlert(_ alert: SkincareAlert) -> Alert {
        switch alert {
        case .saveEmpty:
            Alert(
                title: Text("Save Without Ingredients?"),
                message: Text("This product has no ingredients yet, so it won't generate any ingredient recommendations. Save anyway?"),
                primaryButton: .default(Text("Save Anyway")) {
                    viewModel.confirmSaveEmpty(into: skincareViewModel)
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        case .deleteProduct, .deleteLastProduct:
            Alert(title: Text(""))
        }
    }
}
