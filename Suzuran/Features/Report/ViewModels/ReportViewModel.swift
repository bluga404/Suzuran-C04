import Combine
import Foundation

@MainActor
final class ReportViewModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    init() {}
}
