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
                    PrimaryButton(title: "Mengerti", action: onDismiss)
                }
                .padding(AppSpacing.lg)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Cara scan ingredient")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Pastikan daftar komposisi terlihat jelas agar hasil scan lebih akurat.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var acquisitionMethods: some View {
        VStack(spacing: AppSpacing.sm) {
            ScanGuideRow(
                symbol: "camera.fill",
                title: "Ambil foto label",
                detail: "Arahkan kamera ke daftar ingredient pada kemasan."
            )
            ScanGuideRow(
                symbol: "photo.on.rectangle.angled",
                title: "Pilih dari galeri",
                detail: "Unggah foto label yang tajam dan tidak terpotong."
            )
        }
    }

    private var tips: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("Tips untuk hasil terbaik", systemImage: "lightbulb")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.accentPrimary)

                Text("Gunakan pencahayaan cukup, hindari pantulan, dan pastikan seluruh daftar ingredient berada di dalam bingkai.")
                    .font(AppTypography.caption)
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
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.accentPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColor.accentPrimary.opacity(0.08))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(title)
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
