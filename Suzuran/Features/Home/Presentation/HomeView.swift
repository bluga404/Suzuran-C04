import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var isShowingScanSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Welcome Banner Card
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(viewModel.welcomeText)
                            .font(AppTypography.title)
                            .foregroundStyle(AppColor.textPrimary)

                        Text("Evaluasi perkembangan pemulihan jerawat secara mandiri dengan deteksi AI.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                // Main Scan Action Card
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack {
                            Image(systemName: "face.dashed")
                                .font(.system(size: 36))
                                .foregroundStyle(AppColor.accentPrimary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scan Wajah 360°")
                                    .font(AppTypography.subtitle)
                                    .foregroundStyle(AppColor.textPrimary)

                                Text("Pindai 3 sudut wajah (Depan, Kiri, Kanan)")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }

                        PrimaryButton(
                            title: "Mulai Scan Wajah",
                            action: { isShowingScanSheet = true }
                        )
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .fullScreenCover(isPresented: $isShowingScanSheet) {
            FaceScanFactory.makeView(onDismiss: {
                isShowingScanSheet = false
            })
        }
        .appScreenContainer()
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(welcomeText: AppConstants.homeWelcomeTitle))
}
