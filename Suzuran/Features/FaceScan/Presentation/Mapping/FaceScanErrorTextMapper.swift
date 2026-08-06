import Foundation

enum FaceScanErrorTextMapper {
    static func message(for error: Error) -> String {
        if let domainError = error as? FaceScanDomainError {
            switch domainError {
            case .cameraPermissionDenied:
                return "Izin kamera diperlukan untuk melakukan scan wajah. Silakan aktifkan di Pengaturan."
            case .noFaceDetected:
                return "Wajah tidak terdeteksi. Posisikan wajah Anda di dalam frame."
            case .modelLoadingFailed:
                return "Gagal memuat model deteksi jerawat."
            case let .scanIncomplete(missingZones):
                let zoneNames = missingZones.map { $0.displayName }.joined(separator: ", ")
                return "Scan belum lengkap. Zona berikut belum ter-scan: \(zoneNames)"
            case .insufficientLighting:
                return "Cahaya terlalu redup. Pindah ke tempat yang lebih terang."
            case .emptyScanData:
                return "Tidak ada data scan yang diterima."
            }
        }

        let appError = AppErrorMapper.map(error)
        return appError.userMessage
    }
}
