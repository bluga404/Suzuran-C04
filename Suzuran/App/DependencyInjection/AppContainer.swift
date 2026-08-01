import Combine
import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let faceScanService: FaceScanSessionServicing

    init(faceScanService: FaceScanSessionServicing) {
        self.faceScanService = faceScanService
    }

    convenience init() {
        self.init(faceScanService: FaceScanSessionService())
    }
}
