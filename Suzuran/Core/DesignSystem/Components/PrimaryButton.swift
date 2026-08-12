import SwiftUI

struct PrimaryButton: View {
    enum Style {
        case filled
        case bordered
        case destructive
    }

    let title: String
    let style: Style
    let isLoading: Bool
    let action: () -> Void

    init(
        title: String,
        style: Style = .filled,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                }

                Text(title)
                    .font(Font.description)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.md)
                    .stroke(borderColor, lineWidth: style == .bordered ? 1 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        }
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return AppColor.accentPrimary
        case .bordered:
            return .clear
        case .destructive:
            return AppColor.accentDanger
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .filled, .destructive:
            return .white
        case .bordered:
            return AppColor.textPrimary
        }
    }

    private var borderColor: Color {
        switch style {
        case .bordered:
            return AppColor.borderSubtle
        case .filled, .destructive:
            return .clear
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.sm) {
        PrimaryButton(title: "Primary") {}
        PrimaryButton(title: "Bordered", style: .bordered) {}
        PrimaryButton(title: "Deleting", style: .destructive, isLoading: true) {}
    }
    .padding()
}
