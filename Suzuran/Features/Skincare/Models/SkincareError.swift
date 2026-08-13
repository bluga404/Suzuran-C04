import Foundation

/// Errors surfaced by the Skincare module.
///
/// All error descriptions are provided in Bahasa Indonesia so they can be
/// bound directly to user-facing alerts and snackbars without additional
/// localization at the ViewModel/View layer (Req 19.1, 19.2).
enum SkincareError: LocalizedError, Equatable, CaseIterable {
    case ocrFailed
    case ingredientNotFound
    case databaseUnavailable
    case saveFailed
    case deleteFailed
    case matchingFailed
    case validationFailed

    var errorDescription: String? {
        switch self {
        case .ocrFailed:
            return "Gagal membaca teks dari gambar. Coba ambil ulang dengan pencahayaan yang lebih baik."
        case .ingredientNotFound:
            return "Ingredient tidak ditemukan di database referensi."
        case .databaseUnavailable:
            return "Database ingredient belum siap. Coba lagi sebentar."
        case .saveFailed:
            return "Gagal menyimpan produk. Coba lagi."
        case .deleteFailed:
            return "Gagal menghapus produk. Coba lagi."
        case .matchingFailed:
            return "Gagal mencocokkan ingredient dengan kondisi kulit."
        case .validationFailed:
            return "Lengkapi nama dan brand produk terlebih dahulu."
        }
    }
}
