import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel

    init(appRouter: AppRouter) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(appRouter: appRouter))
    }

    var body: some View {
        VStack(spacing: Spacing.large) {
            HStack {
                Spacer()
                Button("Skip") {
                    viewModel.skipOnboarding()
                }
                .font(Typography.button)
                .foregroundColor(.suzuranSecondary)
                .padding(.trailing, Spacing.large)
            }

            Spacer()

            Image(systemName: viewModel.currentPage.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .foregroundColor(.suzuranAccent)

            VStack(spacing: Spacing.small) {
                Text(viewModel.currentPage.title)
                    .font(Typography.heading)
                    .foregroundColor(.suzuranTextPrimary)
                    .multilineTextAlignment(.center)
                Text(viewModel.currentPage.description)
                    .font(Typography.body)
                    .foregroundColor(.suzuranTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()

            HStack(spacing: Spacing.small) {
                ForEach(0..<viewModel.pageCount, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.pageIndex ? Color.suzuranAccent : Color.suzuranDivider)
                        .frame(width: 10, height: 10)
                }
            }

            Button(action: viewModel.advancePage) {
                Text(viewModel.isLastPage ? "Get Started" : "Next")
                    .font(Typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.suzuranPrimary)
                    .cornerRadius(CornerRadius.card)
                    .padding(.horizontal, Spacing.large)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 18)
        .background(Color.suzuranBackground.ignoresSafeArea())
    }
}

#Preview {
    OnboardingView(appRouter: AppRouter())
}