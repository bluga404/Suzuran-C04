import SwiftUI

/// Add/Edit form built as a custom scroll layout instead of `Form` so its
/// hierarchy follows the mid-fidelity flow: category → product information →
/// scan/review ingredients → persistent bottom save action.
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    categorySection
                    productInformationSection
                    ingredientSection
                }
                .padding(AppSpacing.md)
            }
            .background(AppColor.backgroundPrimary)
            .navigationTitle(viewModel.isEditing ? "Edit Skincare" : "Tambah Skincare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") { dismiss() }
                        .font(Font.description)
                        .foregroundStyle(AppColor.accentPrimary)
                        .frame(minHeight: 44)
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
            .confirmationDialog(
                "Hapus semua bahan?",
                isPresented: $isConfirmingClearAll,
                titleVisibility: .visible
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
    }

    // MARK: - Sections

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Pilih Kategori")
                .font(Font.description)
                .foregroundStyle(AppColor.textPrimary)

            CategorySelector(selected: $viewModel.draft.category)
        }
    }

    private var productInformationSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Informasi Produk")
                    .font(Font.description)
                    .foregroundStyle(AppColor.textPrimary)

                labeledField(
                    title: "Nama Produk",
                    placeholder: "Contoh: Hydrating Serum",
                    text: $viewModel.draft.name
                )

                labeledField(
                    title: "Merek",
                    placeholder: "Contoh: CeraVe",
                    text: $viewModel.draft.brand
                )

                Toggle("Sedang digunakan", isOn: $viewModel.draft.isUsedCurrently)
                    .font(Font.description)
                    .tint(AppColor.accentPrimary)
                    .frame(minHeight: 44)
            }
        }
    }

    private var ingredientSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Ingredient")
                        .font(Font.description)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Pindai label atau tambahkan bahan secara manual.")
                        .font(Font.metadata)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()

                if !viewModel.draft.ingredients.isEmpty {
                    Button("Hapus Semua") { isConfirmingClearAll = true }
                        .font(Font.metadata)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.accentDanger)
                        .frame(minHeight: 44)
                }
            }

            scanAction

            if !viewModel.scannedIngredients.isEmpty {
                scannedReviewSection
            }

            ingredientSearchAction

            if viewModel.draft.ingredients.isEmpty {
                emptyIngredientHint
            } else {
                ingredientChips
            }
        }
    }

    /// Large primary scan affordance, matching the visual priority of mockups 01/03.
    private var scanAction: some View {
        Button { isShowingScanner = true } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "doc.text.viewfinder")
                    .font(Font.description)
                    .foregroundStyle(AppColor.accentPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColor.accentPrimary.opacity(0.08))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Pindai komposisi produk")
                        .font(Font.description)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Gunakan kamera atau pilih foto label")
                        .font(Font.metadata)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(Font.metadata)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .stroke(AppColor.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Buka pilihan kamera atau galeri untuk membaca label")
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

    private var ingredientSearchAction: some View {
        Button { isShowingSearch = true } label: {
            Label("Cari ingredient secara manual", systemImage: "magnifyingglass")
                .font(Font.description)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(AppColor.accentPrimary)
    }

    private var emptyIngredientHint: some View {
        Text("Belum ada ingredient ditambahkan.")
            .font(Font.metadata)
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.sm)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
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

    private func labeledField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(Font.metadata)
                .foregroundStyle(AppColor.textSecondary)

            TextField(placeholder, text: text)
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
