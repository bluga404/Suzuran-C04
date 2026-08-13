import SwiftUI
import Combine

@MainActor
final class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []

    func reset(to route: AppRoute) {
        path = [route]
    }

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        if !path.isEmpty {
            path.removeAll(keepingCapacity: true)
        }
    }
}
