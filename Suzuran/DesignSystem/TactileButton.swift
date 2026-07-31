import SwiftUI

struct TactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Theme.glassStroke, lineWidth: 1.5)
                    )
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.1 : 0.3), radius: configuration.isPressed ? 5 : 10, x: 0, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct TactileButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                        .font(.system(.body, design: .rounded).bold())
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
        }
        .buttonStyle(TactileButtonStyle())
        .disabled(isLoading)
    }
}
