import SwiftUI

struct IngredientReviewView: View {
    @ObservedObject var viewModel: AddSkincareViewModel
    let repository: CosingIngredientRepository
    let onSave: () -> Void

    @State private var query = ""
    @State private var searchResults: [IngredientReference] = []

    var body: some View {
        VStack(spacing: 0) {
            // Instructions
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Tinjau Hasil Pindaian")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                
                Text("Berikut adalah bahan-bahan yang berhasil dideteksi. Anda dapat menghapus yang kurang tepat atau menambahkan yang terlewat.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surfacePrimary)
            
            // Search Bar
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColor.textSecondary)
                
                TextField("Cari kandungan (contoh: Niacinamide)", text: $query)
                    .font(AppTypography.body)
                    .textFieldStyle(.plain)
                    .onChange(of: query) { _, newQuery in
                        performSearch(query: newQuery)
                    }
                
                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
            .padding(AppSpacing.sm)
            .background(AppColor.backgroundPrimary)
            .cornerRadius(AppCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .stroke(AppColor.borderSubtle, lineWidth: 1)
            )
            .padding(AppSpacing.md)
            .background(AppColor.surfacePrimary)
            
            Divider()

            // Main Content List
            List {
                if !query.isEmpty {
                    // Search Mode
                    if !searchResults.contains(where: { $0.normalizedName == query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }) {
                        Section("Kandungan Baru") {
                            Button(action: {
                                addIngredient(query)
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(AppColor.accentPrimary)
                                    Text("Tambah \"\(query)\"")
                                        .font(AppTypography.bodyBold)
                                        .foregroundStyle(AppColor.accentPrimary)
                                }
                            }
                        }
                    }
                    
                    Section("Hasil Pencarian") {
                        if searchResults.isEmpty {
                            Text("Tidak ada hasil ditemukan")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        } else {
                            ForEach(searchResults, id: \.self) { ingredient in
                                Button(action: {
                                    addIngredient(ingredient.name)
                                }) {
                                    HStack {
                                        Text(ingredient.name)
                                            .font(AppTypography.body)
                                            .foregroundStyle(AppColor.textPrimary)
                                        Spacer()
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(AppColor.accentPrimary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Review Scanned Ingredients Mode
                    Section("Kandungan Terdeteksi") {
                        if viewModel.scannedIngredients.isEmpty {
                            Text("Belum ada kandungan terdeteksi. Silakan tambah manual di atas.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.scannedIngredients, id: \.self) { ingredient in
                                HStack {
                                    Text(ingredient.rawText)
                                        .font(AppTypography.body)
                                        .foregroundStyle(AppColor.textPrimary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.scannedIngredients.removeAll { $0 == ingredient }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundStyle(AppColor.accentDanger)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .onDelete { offsets in
                                viewModel.scannedIngredients.remove(atOffsets: offsets)
                            }
                        }
                    }
                }
            }
            .applyConditionalListStyle(isPlain: query.isEmpty)

            // Save Action
            VStack {
                Button(action: {
                    viewModel.commitScannedIngredients()
                    onSave()
                }) {
                    Text("Gunakan Kandungan Ini (\(viewModel.scannedIngredients.count))")
                        .font(AppTypography.bodyBold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColor.accentPrimary)
                        .foregroundStyle(.white)
                        .cornerRadius(AppCornerRadius.md)
                }
                .padding(AppSpacing.md)
            }
            .background(AppColor.surfacePrimary)
            .border(AppColor.borderSubtle, width: 0.5)
        }
        .background(AppColor.backgroundPrimary)
        .navigationTitle("Tinjau Bahan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addIngredient(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !viewModel.scannedIngredients.contains(where: { $0.rawText.lowercased() == trimmed.lowercased() }) {
            viewModel.scannedIngredients.append(OCRIngredientResult(rawText: trimmed))
        }
        query = ""
    }
    
    private func performSearch(query: String) {
        searchResults = repository.searchIngredients(query: query)
    }
}

extension View {
    @ViewBuilder
    func applyConditionalListStyle(isPlain: Bool) -> some View {
        if isPlain {
            self.listStyle(.plain)
        } else {
            self.listStyle(.insetGrouped)
        }
    }
}
