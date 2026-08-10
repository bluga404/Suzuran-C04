import SwiftUI

/// Environment key that allows child views to programmatically switch the active tab.
/// Used by HomeView's "Track Skincare" button to navigate to the Skincare tab.
private struct SwitchToTabKey: EnvironmentKey {
    static let defaultValue: (AppTab) -> Void = { _ in }
}

extension EnvironmentValues {
    var switchToTab: (AppTab) -> Void {
        get { self[SwitchToTabKey.self] }
        set { self[SwitchToTabKey.self] = newValue }
    }
}
