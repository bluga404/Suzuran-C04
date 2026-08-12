import SwiftUI

struct AppButton: View {
    enum Variant {
        case primary
        case bordered
        case destructive
    }

    let title: String
    let variant: Variant
    let isLoading: Bool
    let action: () -> Void

    init(
        title: String,
        variant: Variant = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
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
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
        }
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return AppColor.accentPrimary
        case .bordered:
            return .clear
        case .destructive:
            return AppColor.accentDanger
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return .white
        case .bordered:
            return AppColor.textPrimary
        }
    }

    private var borderColor: Color {
        switch variant {
        case .bordered:
            return AppColor.borderSubtle
        case .primary, .destructive:
            return .clear
        }
    }

    private var borderWidth: CGFloat {
        variant == .bordered ? 1 : 0
    }
}

#Preview {
    VStack(spacing: AppSpacing.sm) {
        AppButton(title: "Primary") {}
        AppButton(title: "Bordered", variant: .bordered) {}
        AppButton(title: "Deleting", variant: .destructive, isLoading: true) {}
    }
    .padding()
}
