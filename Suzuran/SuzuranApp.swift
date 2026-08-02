import SwiftUI
import Combine

@main
struct SuzuranApp: App {
    @StateObject private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: container.rootViewModel)
        }
    }
}

