import SwiftUI

struct PermissionStateView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        EmptyStateView(
            title: title,
            message: message,
            actionTitle: actionTitle,
            onAction: action
        )
    }
}
