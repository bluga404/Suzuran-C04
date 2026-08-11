import SwiftUI

struct IngredientSearchView: View {
    @Environment(\.dismiss) private var dismiss
    let repository: CosingIngredientRepository
    let onSelect: (String) -> Void
    
    @State private var query = ""
    @State private var results: [IngredientReference] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                .background(AppColor.surfacePrimary)
                .cornerRadius(AppCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.md)
                        .stroke(AppColor.borderSubtle, lineWidth: 1)
                )
                .padding(AppSpacing.md)
                
                // Search Results
                List {
                    if !query.isEmpty && !results.contains(where: { $0.normalizedName == query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }) {
                        Section("Kandungan Baru") {
                            Button(action: {
                                onSelect(query)
                                dismiss()
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
                        if results.isEmpty {
                            if query.isEmpty {
                                Text("Ketik untuk mencari kandungan skincare...")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                            } else {
                                Text("Tidak ada hasil ditemukan")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        } else {
                            ForEach(results, id: \.self) { ingredient in
                                Button(action: {
                                    onSelect(ingredient.name)
                                    dismiss()
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
                }
                .listStyle(.insetGrouped)
            }
            .background(AppColor.backgroundPrimary)
            .navigationTitle("Cari Kandungan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.accentPrimary)
                }
            }
        }
    }

    private func performSearch(query: String) {
        results = repository.search(query: query).map { $0.name }
    }
}
