import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    let onNavigateToIngredientOcr: () -> Void

    var body: some View {
        VStack {
            Text(viewModel.viewState.welcomeText)
                .font(AppTypography.title)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(AppSpacing.lg)
                .appScreenContainer()

            Button(viewModel.viewState.ingredientOcrButtonTitle) {
                onNavigateToIngredientOcr()
            }
        }
    }
}

#Preview {
    HomeView(
        viewModel: HomeViewModel(
            welcomeText: AppConstants.homeWelcomeTitle,
            ingredientOcrButtonTitle: AppConstants.homeIngredientOcrButtonTitle
        ),
        onNavigateToIngredientOcr: {}
    )
}
