import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel

    init(viewModel: OnboardingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: SpacingToken.large) {
            HStack {
                Spacer()
                Button("Skip") {
                    viewModel.skip()
                }
                .font(FontToken.button)
                .foregroundColor(ColorToken.secondary)
                .padding(.trailing, SpacingToken.large)
            }

            Spacer()

            Image(systemName: viewModel.currentPage.symbolName)
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .foregroundColor(ColorToken.accent)

            VStack(spacing: SpacingToken.small) {
                Text(viewModel.currentPage.title)
                    .font(FontToken.heading)
                    .foregroundColor(ColorToken.textPrimary)
                    .multilineTextAlignment(.center)
                Text(viewModel.currentPage.description)
                    .font(FontToken.body)
                    .foregroundColor(ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SpacingToken.extraLarge)
            }

            Spacer()

            HStack(spacing: SpacingToken.small) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, _ in
                    Circle()
                        .fill(index == viewModel.pageIndex ? ColorToken.accent : ColorToken.divider)
                        .frame(width: 10, height: 10)
                }
            }

            Button(action: viewModel.advance) {
                Text(viewModel.isLastPage ? "Get Started" : "Next")
                    .font(FontToken.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorToken.primary)
                    .cornerRadius(CornerRadiusToken.card)
                    .padding(.horizontal, SpacingToken.large)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 18)
        .background(ColorToken.background.ignoresSafeArea())
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(appRouter: AppRouter()))
}
