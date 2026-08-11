import Foundation

protocol AcneProfileProviding {
    func getActiveAcneTypes() -> [AcneType]
}

final class AcneProfileProvider: AcneProfileProviding {
    func getActiveAcneTypes() -> [AcneType] {
        // Mock data. In a real integration, this would retrieve the latest scan results.
        return [.whitehead, .blackhead, .pustule]
    }
}
