import SwiftUI

@main
struct SuzuranApp: App {
    @StateObject private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView(
                viewModel: container.rootViewModel,
                dependencies: container.makeRootViewDependencies()
            )
        }
    }
}

