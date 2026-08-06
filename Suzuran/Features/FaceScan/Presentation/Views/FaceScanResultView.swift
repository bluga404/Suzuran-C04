import SwiftUI

struct FaceScanResultView: View {
    let result: FaceScanResultModel
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header Card
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack {
                            Text("Hasil Scan Wajah")
                                .font(AppTypography.title)
                                .foregroundStyle(AppColor.textPrimary)

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(AppColor.accentPrimary)
                        }

                        Text(result.dateText)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)

                        Divider()
                            .padding(.vertical, AppSpacing.xxs)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Tingkat Keparahan")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                                Text(result.overallSeverityText)
                                    .font(AppTypography.bodyBold)
                                    .foregroundStyle(AppColor.textPrimary)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("Total Jerawat")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                                Text(result.totalAcneCountText)
                                    .font(AppTypography.bodyBold)
                                    .foregroundStyle(AppColor.accentPrimary)
                            }
                        }
                    }
                }

                Text("Peta Jerawat Wajah")
                    .font(AppTypography.subtitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.top, AppSpacing.xs)

                FaceMaskScanVisualization(markers: result.faceMarkers)

                Text("Jenis Jerawat")
                    .font(AppTypography.subtitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.top, AppSpacing.xs)

                if result.acneTypeSummaries.isEmpty {
                    AppCard {
                        Text("Tidak ada jerawat yang terdeteksi.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                } else {
                    ForEach(result.acneTypeSummaries) { typeSummary in
                        AcneTypeCountRow(summary: typeSummary)
                    }
                }

                Text("Rincian Per Zona Wajah")
                    .font(AppTypography.subtitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.top, AppSpacing.xs)

                ForEach(result.zoneSummaries) { zone in
                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack {
                                Text(zone.zoneName)
                                    .font(AppTypography.bodyBold)
                                    .foregroundStyle(AppColor.textPrimary)

                                Spacer()

                                Text("\(zone.acneCount) jerawat")
                                    .font(AppTypography.caption)
                                    .padding(.horizontal, AppSpacing.xs)
                                    .padding(.vertical, AppSpacing.xxs)
                                    .background(
                                        Capsule()
                                            .fill(zone.acneCount > 0 ? AppColor.accentDanger.opacity(0.15) : AppColor.accentPrimary.opacity(0.15))
                                    )
                                    .foregroundStyle(zone.acneCount > 0 ? AppColor.accentDanger : AppColor.accentPrimary)
                            }

                            Text(zone.detailText)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }

                PrimaryButton(title: "Selesai", action: onDone)
                    .padding(.top, AppSpacing.md)
            }
            .padding(AppSpacing.md)
        }
        .appScreenContainer()
    }
}
