import SwiftUI

struct AppTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(Font.description)
                .foregroundStyle(AppColor.textPrimary)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding(AppSpacing.sm)
                .background(AppColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.md)
                        .stroke(errorMessage == nil ? AppColor.borderSubtle : AppColor.accentDanger, lineWidth: 1)
                )

            if let errorMessage {
                Text(errorMessage)
                    .font(Font.metadata)
                    .foregroundStyle(AppColor.accentDanger)
            }
        }
    }
}
