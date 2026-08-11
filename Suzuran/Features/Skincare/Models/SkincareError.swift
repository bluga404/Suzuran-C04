import Foundation

enum SkincareError: LocalizedError {
    case ocrFailed
    case ingredientNotFound
    case databaseUnavailable
    case saveFailed
    case deleteFailed
    case matchingFailed
    
    var errorDescription: String? {
        switch self {
        case .ocrFailed: return "Gagal membaca teks dari gambar. Pastikan gambar jelas."
        case .ingredientNotFound: return "Bahan tidak ditemukan dalam database."
        case .databaseUnavailable: return "Database skincare sedang tidak tersedia."
        case .saveFailed: return "Gagal menyimpan data skincare."
        case .deleteFailed: return "Gagal menghapus data skincare."
        case .matchingFailed: return "Gagal mencocokkan bahan dengan tipe jerawat."
        }
    }
}
