import SwiftUI

/// Full-screen scan guide. The hierarchy follows the mid-fidelity modal:
/// acquisition methods first, then a concise tips panel, followed by one clear
/// acknowledgement action. It deliberately holds no OCR state.
struct ScanInstructionModalView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AppColor.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header
                    acquisitionMethods
                    tips
                    AppButton(title: "Got It", action: onDismiss)
                }
                .padding(AppSpacing.lg)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("How to scan ingredients")
                .font(Font.screenTitle)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Make sure the ingredient list is clearly visible for more accurate scan results.")
                .font(Font.description)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var acquisitionMethods: some View {
        VStack(spacing: AppSpacing.sm) {
            ScanGuideRow(
                symbol: "camera.fill",
                title: "Take a photo of the label",
                detail: "Point the camera at the ingredient list on the packaging."
            )
            ScanGuideRow(
                symbol: "photo.on.rectangle.angled",
                title: "Choose from gallery",
                detail: "Upload a sharp and uncut photo of the label."
            )
        }
    }

    private var tips: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("Tips for best results", systemImage: "lightbulb")
                    .font(Font.description)
                    .foregroundStyle(AppColor.accentPrimary)

                Text("Use adequate lighting, avoid glare, and make sure the entire ingredient list is within the frame.")
                    .font(Font.metadata)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}

private struct ScanGuideRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        AppCard {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: symbol)
                    .font(Font.description)
                    .foregroundStyle(AppColor.accentPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColor.accentPrimary.opacity(0.08))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(title)
                        .font(Font.description)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(detail)
                        .font(Font.metadata)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
