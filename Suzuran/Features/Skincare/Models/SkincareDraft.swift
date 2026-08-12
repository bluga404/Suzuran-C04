import Foundation

// menerima `category: SkincareCategory` dan `ingredients: [IngredientReference]`.
// File ini menulis `toProduct(existingID:)` sesuai design.md; build lengkap akan

/// Value type yang menampung state form Add Skincare secara terisolasi dari
/// `SkincareProductRepository`.
///
/// `AddSkincareViewModel` memelihara satu instance `SkincareDraft` selama
/// pengguna berada di form. Perubahan pada draft **tidak** menyentuh data
/// tersimpan sampai `commitSave` dieksekusi — sesuai kontrak _draft isolation_
///
/// - Cancel: view dismiss membuang draft; tidak ada perubahan persisted
/// - Save: `toProduct(existingID:)` dipanggil sekali untuk membentuk payload
///
/// **Bukan `Codable`**: draft tidak pernah dipersist dan hanya hidup selama
/// lifecycle ViewModel.
///
struct SkincareDraft {
    var name: String
    var brand: String
    var category: SkincareCategory?
    var ingredients: [IngredientReference]
    var isUsedCurrently: Bool

    /// Seed draft dari produk yang sedang diedit, atau default value untuk
    /// pembuatan produk baru.
    ///
    /// - Parameter product: Produk yang sedang diedit. Bila `nil`, draft dimulai
    ///   dengan field kosong, kategori belum dipilih (`nil`), dan
    ///   `isUsedCurrently = true`.
    init(from product: SkincareProduct? = nil) {
        self.name = product?.name ?? ""
        self.brand = product?.brand ?? ""
        self.category = product?.category
        self.ingredients = product?.ingredients ?? []
        self.isUsedCurrently = product?.isUsedCurrently ?? true
    }

    /// `true` bila `name` non-empty setelah trim whitespace.
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && category != nil
    }

    /// Bentuk `SkincareProduct` dari state draft saat ini.
    ///
    /// - Parameter existingID: `id` produk yang sedang diedit; `nil` untuk produk
    ///   baru (akan dibuat `UUID()` baru).
    /// - Returns: `SkincareProduct` dengan `name`/`brand` yang sudah di-trim.
    ///   Bila `category` belum dipilih, digunakan `.moisturizer` sebagai fallback.
    func toProduct(existingID: UUID?) -> SkincareProduct {
        SkincareProduct(
            id: existingID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            brand: brand.trimmingCharacters(in: .whitespaces),
            category: category ?? .moisturizer,
            ingredients: ingredients,
            isUsedCurrently: isUsedCurrently
        )
    }
}
