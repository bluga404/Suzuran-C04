import SwiftUI

/// Represents the available tabs in the app's root TabView.
enum AppTab: Hashable {
    case summary
    case skincare
    case history
    case report
}

/// Root TabView with iOS 26 Liquid Glass styling (applied automatically).
/// Uses the `Tab` initializer for native tab bar appearance.
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
            Tab("Summary", systemImage: "heart.text.square.fill", value: .summary) {
                HomeView(viewModel: homeSummaryViewModel, historyStore: viewModel.scanHistoryStore)
                    .environment(\.switchToTab) { tab in
                        selectedTab = tab
                    }
            }

            Tab("Skincare", systemImage: "viewfinder", value: .skincare) {
                SkincareFactory.makeView()
            }

            Tab("History", systemImage: "photo.on.rectangle.angled", value: .history) {
                HistoryFactory.makeView(historyStore: viewModel.scanHistoryStore)
            }

            Tab("Report", systemImage: "chart.line.uptrend.xyaxis", value: .report) {
                ReportFactory.makeView()
            }
        }
        .tint(AppColor.accentPrimary)
    }
}

#Preview {
    MainTabView(
        viewModel: RootViewModel(
            bootstrapper: PreviewBootstrapper(),
            scanHistoryStore: ScanHistoryStore(),
            homeSummaryViewModelFactory: { HomeFactory.makeViewModel() }
        )
    )
}

/// Bootstrapper stub for previews.
private struct PreviewBootstrapper: AppBootstrapping {
    func bootstrap() async throws {}
}
