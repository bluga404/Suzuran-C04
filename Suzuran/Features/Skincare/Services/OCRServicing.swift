import UIKit

/// Protocol yang mendefinisikan kontrak layanan OCR untuk mengekstrak teks dari gambar.
///
/// Digunakan sebagai abstraksi untuk memisahkan logika OCR dari caller (ViewModel),
/// sehingga memudahkan dependency injection dan testing (misal via mock).
///
/// - SeeAlso: `IngredientOCRService` untuk implementasi konkret berbasis Vision.
protocol OCRServicing {
    /// Mengenali teks pada `image` dan mengembalikannya sebagai string.
    ///
    /// - Parameter image: Gambar sumber yang akan dianalisis.
    /// - Returns: Teks yang berhasil dikenali dari gambar, joined per baris dengan `\n`.
    /// - Throws: Error dari pipeline OCR (contoh: gambar invalid atau kegagalan Vision).
    func recognizeText(from image: UIImage) async throws -> String
}

// MARK: - Conformance

/// Menambahkan conformance `OCRServicing` ke implementasi eksisting `IngredientOCRService`.
///
/// Signature `recognizeText(from:)` sudah sesuai dengan protocol, sehingga cukup
/// menambahkan conformance tanpa mengubah implementasi.
extension IngredientOCRService: OCRServicing {}
