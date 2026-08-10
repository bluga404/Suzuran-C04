import SwiftUI

/// Represents the available tabs in the app's root TabView.
enum AppTab: Hashable {
    case summary
    case skincare
    case history
    case profile
}

/// Root TabView with iOS 26 Liquid Glass styling (applied automatically).
/// Uses the `Tab` initializer for native tab bar appearance.
/// The HomeSummaryViewModel is owned as @StateObject to prevent recreation
/// on every SwiftUI body re-evaluation.
struct MainTabView: View {
    @ObservedObject var viewModel: RootViewModel
    @State private var selectedTab: AppTab = .summary
    @StateObject private var homeSummaryViewModel: HomeSummaryViewModel

    init(viewModel: RootViewModel) {
        self.viewModel = viewModel
        self._homeSummaryViewModel = StateObject(wrappedValue: viewModel.makeHomeSummaryViewModel())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Summary", systemImage: "house.fill", value: .summary) {
                HomeView(viewModel: homeSummaryViewModel)
                    .environment(\.switchToTab) { tab in
                        selectedTab = tab
                    }
            }

            Tab("Skincare", systemImage: "leaf.fill", value: .skincare) {
                SkincareView()
            }

            Tab("History", systemImage: "chart.line.uptrend.xyaxis", value: .history) {
                HistoryView()
            }

            Tab("Profile", systemImage: "person.fill", value: .profile) {
                ProfileView()
            }
        }
        .tint(AppColor.accentPrimary)
    }
}

#Preview {
    MainTabView(
        viewModel: RootViewModel(
            bootstrapper: PreviewBootstrapper(),
            homeSummaryViewModelFactory: { HomeFactory.makeViewModel() }
        )
    )
}

/// Bootstrapper stub for previews.
private struct PreviewBootstrapper: AppBootstrapping {
    func bootstrap() async throws {}
}
