import SwiftUI

/// Summary tab — placeholder with scan button.
/// This will be the first tab and has a "Mulai Scan" button for now.
struct SummaryView: View {
    @ObservedObject var historyStore: ScanHistoryStore
    var onStartScan: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Selamat Datang di Suzuran")
                                .font(AppTypography.title)
                                .foregroundStyle(.primary)

                            Text("Evaluasi perkembangan pemulihan jerawat secara mandiri dengan deteksi AI.")
                                .font(AppTypography.body)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Quick skin score from latest scan
                    if let latest = historyStore.records.first {
                        AppCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Scan Terakhir")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Text("\(latest.skinScore)%")
                                        .font(.custom("AvenirNext-Bold", size: 44, relativeTo: .largeTitle))
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                                        Text(latest.severity.rawValue.capitalized)
                                            .font(.custom("AvenirNext-Bold", size: 13, relativeTo: .caption))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, AppSpacing.sm)
                                            .padding(.vertical, AppSpacing.xxs)
                                            .background(Capsule().fill(severityColor(latest.severity)))

                                        Text("\(latest.totalAcneCount) jerawat")
                                            .font(AppTypography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    // Scan action card
                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            HStack {
                                Image(systemName: "face.dashed")
                                    .font(.custom("AvenirNext-Regular", size: 36, relativeTo: .largeTitle))
                                    .foregroundStyle(AppColor.accentPrimary)

                                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                    Text("Scan Wajah 360°")
                                        .font(AppTypography.subtitle)
                                        .foregroundStyle(.primary)

                                    Text("Pindai 3 sudut wajah (Depan, Kiri, Kanan)")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            PrimaryButton(
                                title: "Mulai Scan Wajah",
                                action: onStartScan
                            )
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .navigationTitle("Summary")
        }
    }

    private func severityColor(_ severity: AcneSeverity) -> Color {
        switch severity {
        case .clear:    return AppColor.scoreVeryGood
        case .mild:     return AppColor.scoreGood
        case .moderate: return AppColor.scoreModerate
        case .severe:   return AppColor.scoreVeryLow
        }
    }
}
