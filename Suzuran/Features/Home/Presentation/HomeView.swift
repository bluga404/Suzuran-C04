import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        Text(viewModel.welcomeText)
            .font(AppTypography.title)
            .foregroundStyle(AppColor.textPrimary)
            .multilineTextAlignment(.center)
            .padding(AppSpacing.lg)
            .appScreenContainer()
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(welcomeText: AppConstants.homeWelcomeTitle))
}
