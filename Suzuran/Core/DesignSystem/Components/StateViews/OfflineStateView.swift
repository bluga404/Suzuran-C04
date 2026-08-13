import SwiftUI

struct OfflineStateView: View {
    let onRetry: () -> Void

    var body: some View {
        EmptyStateView(
            title: "You Are Offline",
            message: "Reconnect to the internet and try again.",
            actionTitle: "Retry",
            onAction: onRetry
        )
    }
}
