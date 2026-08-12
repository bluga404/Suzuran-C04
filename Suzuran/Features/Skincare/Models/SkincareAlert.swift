import Foundation

// File ini menulis case `saveEmpty(SkincareDraft)` sesuai design.md; build lengkap

/// Enum konfirmasi yang dipakai bersama `.alert(item:)` pada `SkincareView`
/// dan `AddSkincareView`. Setiap case membawa payload sesuai konteks:
///
/// - ``deleteProduct(_:)``: konfirmasi hapus satu produk (mockup `07A_DeleteSkincare.png`).
/// - ``deleteLastProduct(_:)``: konfirmasi hapus produk terakhir; setelah eksekusi
///   Skincare Home kembali ke empty state (Req 17.4).
/// - ``saveEmpty(_:)``: konfirmasi simpan draft tanpa ingredient (mockup
///   `06A_SaveEmptySkincare.png`, Req 16.1).
///
enum SkincareAlert: Identifiable {
    case deleteProduct(SkincareProduct)
    case deleteLastProduct(SkincareProduct)
    case saveEmpty(SkincareDraft)

    /// Identitas stabil per case + payload agar `.alert(item:)` dapat
    /// membedakan alert saat state berubah.
    var id: String {
        switch self {
        case .deleteProduct(let product):
            return "delete-\(product.id)"
        case .deleteLastProduct(let product):
            return "delete-last-\(product.id)"
        case .saveEmpty:
            // Draft tidak memiliki identitas persisten dan hanya satu alert
            // save-empty aktif pada satu waktu (owned oleh `AddSkincareViewModel`).
            return "save-empty"
        }
    }
}
