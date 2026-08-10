import SwiftUI

/// Tab enum matching the 4 tabs from the design.
enum AppTab: String, CaseIterable, Identifiable {
    case summary = "Summary"
    case skincare = "Skincare"
    case history = "History"
    case report = "Report"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .summary:  return "heart.text.square.fill"
        case .skincare: return "viewfinder"
        case .history:  return "photo.on.rectangle.angled"
        case .report:   return "chart.line.uptrend.xyaxis"
        }
    }
}

/// Main Container View that hosts the 4 feature tabs using native SwiftUI TabView.
struct MainTabView: View {
    @ObservedObject var historyStore: ScanHistoryStore
    @State private var selectedTab: AppTab = .history
    @State private var isShowingScanSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            SummaryView(historyStore: historyStore, onStartScan: {
                isShowingScanSheet = true
            })
            .tabItem {
                Label(AppTab.summary.rawValue, systemImage: AppTab.summary.iconName)
            }
            .tag(AppTab.summary)

            SkincareTabView()
                .tabItem {
                    Label(AppTab.skincare.rawValue, systemImage: AppTab.skincare.iconName)
                }
                .tag(AppTab.skincare)

            HistoryFactory.makeView(historyStore: historyStore)
                .tabItem {
                    Label(AppTab.history.rawValue, systemImage: AppTab.history.iconName)
                }
                .tag(AppTab.history)

            ReportTabView()
                .tabItem {
                    Label(AppTab.report.rawValue, systemImage: AppTab.report.iconName)
                }
                .tag(AppTab.report)
        }
        .fullScreenCover(isPresented: $isShowingScanSheet) {
            FaceScanFactory.makeView(
                onDismiss: {
                    isShowingScanSheet = false
                },
                onSave: { result in
                    historyStore.save(result)
                }
            )
        }
    }
}
