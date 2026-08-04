import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                Text(viewModel.welcomeText)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(AppSpacing.lg)

                NavigationLink {
                    AcneScannerView()
                } label: {
                    Label("Test ML Model", systemImage: "viewfinder.circle.fill")
                        .font(AppTypography.bodyBold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColor.accentPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
            .appScreenContainer()
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(welcomeText: AppConstants.homeWelcomeTitle))
}
