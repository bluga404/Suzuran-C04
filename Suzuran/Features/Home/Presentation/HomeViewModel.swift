import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    let welcomeText: String

    init(welcomeText: String) {
        self.welcomeText = welcomeText
    }
}
