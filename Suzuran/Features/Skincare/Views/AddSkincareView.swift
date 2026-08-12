import SwiftUI
import UIKit
import PhotosUI

/// Add/Edit form built as a custom scroll layout instead of `Form` so its
/// hierarchy follows the mid-fidelity flow: category → product information →
/// scan/review ingredients → persistent bottom save action.
struct AddSkincareView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var skincareViewModel: SkincareViewModel
    @StateObject private var viewModel: AddSkincareViewModel

    @State private var isShowingCamera = false
    @State private var isShowingPhotoSource = false
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isConfirmingClearAll = false
    @State private var manualCandidate = ""
    @State private var searchResults: [String] = []

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
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker(selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $isShowingPhotoSource) {
                PhotoSourceSheet(
                    isShowingCamera: $isShowingCamera,
                    selectedItem: $selectedItem
                )
                .presentationDetents([.height(180)])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: selectedImage) { _, image in
                if let image = image {
                    Task { await viewModel.processImage(image) }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                isShowingPhotoSource = false
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run { selectedImage = image }
                    }
                }
            }
            .overlay {
                if viewModel.isScanning {
                    ZStack {
                        AppColor.backgroundPrimary.opacity(0.8)
                            .ignoresSafeArea()

                        VStack(spacing: AppSpacing.sm) {
                            ProgressView()
                                .tint(AppColor.accentPrimary)
                            Text("Membaca teks komposisi...")
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColor.textPrimary)
                        }
                        .padding(AppSpacing.lg)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
                    }
                }
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

    // MARK: - Sections

    private var categorySection: some View {
        AppCard {
            HStack {
                Text("Kategori")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.textPrimary)
                
                Spacer()
                
                Picker("Kategori", selection: $viewModel.draft.category) {
                    ForEach(SkincareCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppColor.accentPrimary)
            }
        }
    }

    private var productInformationSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Informasi Produk")
                    .font(AppTypography.bodyBold)
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

            }
        }
    }

    private var ingredientSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Ingredients")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.textPrimary)

                Spacer()

                if !viewModel.draft.ingredients.isEmpty {
                    Button("Hapus Semua") { isConfirmingClearAll = true }
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.accentDanger)
                        .frame(minHeight: 44)
                }
            }

            scanAction

            if !viewModel.scannedIngredients.isEmpty {
                scannedReviewSection
            }

            ingredientChips
        }
    }

    /// Large primary scan affordance, matching the visual priority of mockups 01/03.
    private var scanAction: some View {
        Button { isShowingPhotoSource = true } label: {
            VStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(AppColor.accentPrimary.opacity(0.1))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "viewfinder.rectangular")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(AppColor.accentPrimary)
                }
                
                Text("Use the camera to scan the product")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(AppColor.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                    .foregroundStyle(AppColor.accentPrimary.opacity(0.4))
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Buka kamera untuk membaca label")
    }

    /// OCR candidates stay in the Add screen for review and manual correction,
    /// matching mockup 04 rather than moving the user into a disconnected screen.
    private var scannedReviewSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Tinjau Hasil Scan")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Hapus kandidat yang kurang tepat atau tambahkan ingredient yang terlewat.")
                    .font(AppTypography.caption)
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
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.xs) {
                TextField("Tambah ingredient manual", text: $manualCandidate)
                    .font(AppTypography.body)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, AppSpacing.sm)
                    .frame(minHeight: 44)
                    .background(AppColor.backgroundPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                            .stroke(AppColor.borderSubtle, lineWidth: 1)
                    )
                    .onChange(of: manualCandidate) { _, newValue in
                        if newValue.isEmpty {
                            searchResults = []
                        } else {
                            searchResults = ingredientRepo.search(query: newValue).map { $0.name }
                        }
                    }
                    .onSubmit(addManualCandidate)

                Button(action: addManualCandidate) {
                    Image(systemName: "plus")
                        .font(AppTypography.bodyBold)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.accentPrimary)
                .accessibilityLabel("Tambah ingredient manual")
            }
            
            if !searchResults.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(searchResults.prefix(5), id: \.self) { result in
                            Button(action: {
                                manualCandidate = result
                                addManualCandidate()
                            }) {
                                Text(result)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.textPrimary)
                                    .padding(.vertical, AppSpacing.sm)
                                    .padding(.horizontal, AppSpacing.md)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 180)
                .background(AppColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                        .stroke(AppColor.borderSubtle, lineWidth: 1)
                )
                .padding(.top, 4)
            }
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

    private func labeledField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)

            TextField(placeholder, text: text)
                .font(AppTypography.body)
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

// MARK: - PhotoSourceSheet

struct PhotoSourceSheet: View {
    @Binding var isShowingCamera: Bool
    @Binding var selectedItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isShowingCamera = true
                }
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Ambil Foto Label")
                        .font(AppTypography.bodyBold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColor.accentPrimary)
                .foregroundStyle(AppColor.textOnAccent)
                .cornerRadius(AppCornerRadius.md)
            }

            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Pilih dari Galeri")
                        .font(AppTypography.bodyBold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColor.surfacePrimary)
                .foregroundStyle(AppColor.accentPrimary)
                .cornerRadius(AppCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.md)
                        .stroke(AppColor.accentPrimary, lineWidth: 1.5)
                )
            }
        }
        .padding(AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
    }
}
