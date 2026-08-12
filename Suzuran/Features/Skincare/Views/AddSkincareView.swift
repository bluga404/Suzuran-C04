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
    /// When `false` (view pushed onto a stack), the system back button is the
    /// way out so the leading "Batal" button is hidden.
    let showsCancelButton: Bool

    init(
        skincareViewModel: SkincareViewModel,
        ingredientRepo: IngredientRepositoryProtocol,
        makeViewModel: @escaping @MainActor () -> AddSkincareViewModel,
        showsCancelButton: Bool = true
    ) {
        self.skincareViewModel = skincareViewModel
        self.ingredientRepo = ingredientRepo
        self.showsCancelButton = showsCancelButton
        self._viewModel = StateObject(wrappedValue: makeViewModel())
    }

    var body: some View {
        Form {
            Section("Informasi Produk") {
                Picker("Kategori", selection: $viewModel.draft.category) {
                    ForEach(SkincareCategory.allCases) { category in
                        Text(category.displayName).tag(Optional(category))
                    }
                }
                .pickerStyle(.menu)
                .font(Font.description)

                TextField("Nama Produk", text: $viewModel.draft.name)
                    .font(Font.description)
                    .textInputAutocapitalization(.words)
            }

            ingredientSection
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.backgroundPrimary)
        .navigationTitle(viewModel.isEditing ? "Edit Skincare" : "Tambah Skincare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCancelButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") { dismiss() }
                        .font(Font.description)
                        .foregroundStyle(AppColor.accentPrimary)
                        .frame(minHeight: 44)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: viewModel.isEditing ? "Simpan Perubahan" : "Simpan Skincare",
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
            "Hapus semua bahan?",
            isPresented: $isConfirmingClearAll
        ) {
            Button("Hapus Semua", role: .destructive) { viewModel.confirmClearAll() }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Semua bahan kandungan pada draft ini akan dihapus. Nama, merek, dan kategori tetap dipertahankan.")
        }
        .alert(item: $viewModel.alert, content: makeSaveEmptyAlert)
        .alert(
            "Data Belum Lengkap",
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
                    
                    Text("Pindai komposisi produk")
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
                    
                    Text("Cari ingredient secara manual")
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
                Text("Ingredient")
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .font(.footnote)

                Spacer()

                if !viewModel.draft.ingredients.isEmpty {
                    Button("Hapus Semua") { isConfirmingClearAll = true }
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
                Text("Tinjau Hasil Scan")
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Hapus kandidat yang kurang tepat atau tambahkan ingredient yang terlewat.")
                    .font(Font.metadata)
                    .foregroundStyle(AppColor.textSecondary)

                candidateChips
                manualCandidateField

                PrimaryButton(title: "Gunakan Ingredient Ini") {
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
            TextField("Tambah ingredient manual", text: $manualCandidate)
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
            .accessibilityLabel("Tambah ingredient manual")
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
                title: Text("Simpan Tanpa Bahan?"),
                message: Text("Produk ini belum memiliki bahan kandungan, sehingga tidak akan menghasilkan rekomendasi ingredient yang cocok. Tetap simpan?"),
                primaryButton: .default(Text("Simpan Tetap")) {
                    viewModel.confirmSaveEmpty(into: skincareViewModel)
                },
                secondaryButton: .cancel(Text("Batal"))
            )
        case .deleteProduct, .deleteLastProduct:
            Alert(title: Text(""))
        }
    }
}
