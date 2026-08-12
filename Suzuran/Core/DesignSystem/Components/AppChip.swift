import SwiftUI

struct AppChip<Content: View>: View {
    enum Variant {
        case filled
        case outlined
    }

    let isActive: Bool
    let variant: Variant
    let activeColor: Color
    let inactiveBorderColor: Color?
    private let content: Content

    init(
        isActive: Bool = false,
        variant: Variant = .filled,
        activeColor: Color = AppColor.accentPrimary,
        inactiveBorderColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.isActive = isActive
        self.variant = variant
        self.activeColor = activeColor
        self.inactiveBorderColor = inactiveBorderColor
        self.content = content()
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            content
        }
        .font(Font.metadata)
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .frame(minHeight: 44)
        .background(backgroundColor)
        .overlay(
            Capsule()
                .stroke(effectiveBorderColor, lineWidth: borderWidth)
        )
        .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        if isActive {
            return variant == .filled ? activeColor : activeColor.opacity(0.12)
        }

        return AppColor.backgroundPrimary
    }

    private var foregroundColor: Color {
        if isActive {
            return variant == .filled ? AppColor.textOnAccent : activeColor
        }

        return AppColor.textPrimary
    }

    private var effectiveBorderColor: Color {
        if isActive {
            return variant == .filled ? .clear : activeColor
        }

        return inactiveBorderColor ?? activeColor.opacity(0.16)
    }

    private var borderWidth: CGFloat {
        isActive && variant == .filled ? 0 : 1
    }
}

#Preview {
    VStack(spacing: AppSpacing.sm) {
        AppChip {
            Text("Inactive")
        }

        AppChip(isActive: true) {
            Text("Active")
        }

        AppChip(isActive: true, activeColor: .green) {
            Text("Custom Active")
        }
    }
    .padding()
}
