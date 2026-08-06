import Foundation

enum FaceZone: String, CaseIterable, Equatable, Codable {
    case forehead
    case rightCheek
    case leftCheek
    case nose
    case chin
    case jawline

    var displayName: String {
        switch self {
        case .forehead: return "Jidat"
        case .rightCheek: return "Pipi Kanan"
        case .leftCheek: return "Pipi Kiri"
        case .nose: return "Hidung"
        case .chin: return "Dagu"
        case .jawline: return "Garis Rahang"
        }
    }

    var instruction: String {
        switch self {
        case .forehead:
            return "Tundukkan kepala sedikit agar jidat terlihat"
        case .rightCheek:
            return "Putar wajah sedikit ke KIRI agar pipi kanan terlihat"
        case .leftCheek:
            return "Putar wajah sedikit ke KANAN agar pipi kiri terlihat"
        case .nose:
            return "Hadapkan wajah lurus agar hidung terlihat jelas"
        case .chin:
            return "Dongakkan wajah sedikit agar dagu terlihat jelas"
        case .jawline:
            return "Miringkan kepala agar garis rahang terlihat"
        }
    }

    var order: Int {
        switch self {
        case .forehead: return 1
        case .rightCheek: return 2
        case .leftCheek: return 3
        case .nose: return 4
        case .chin: return 5
        case .jawline: return 6
        }
    }
}
