import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var appRouter: AppRouter

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $appRouter.homePath) {
            VStack(alignment: .leading, spacing: SpacingToken.large) {
                VStack(alignment: .leading, spacing: SpacingToken.small) {
                    Text(viewModel.greeting)
                        .font(FontToken.title)
                        .foregroundColor(ColorToken.textPrimary)
                    Text(viewModel.details)
                        .font(FontToken.body)
                        .foregroundColor(ColorToken.textSecondary)
                }
                .padding(.horizontal, SpacingToken.large)
                .padding(.top, SpacingToken.large)

                RoundedRectangle(cornerRadius: CornerRadiusToken.card, style: .continuous)
                    .fill(ColorToken.surface)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 10)
                    .overlay(
                        VStack(alignment: .leading, spacing: 14) {
                            Text(viewModel.summary.title)
                                .font(FontToken.heading)
                                .foregroundColor(ColorToken.textPrimary)
                            Text(viewModel.summary.subtitle)
                                .font(FontToken.body)
                                .foregroundColor(ColorToken.textSecondary)
                        }
                        .padding(SpacingToken.large)
                    )
                    .padding(.horizontal, SpacingToken.large)

                Button(action: viewModel.openFaceScan) {
                    RoundedRectangle(cornerRadius: CornerRadiusToken.card, style: .continuous)
                        .fill(ColorToken.surface)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 10)
                        .overlay(
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("FaceScan")
                                        .font(FontToken.heading)
                                        .foregroundColor(ColorToken.textPrimary)
                                    Text("Capture a face scan in a guided flow.")
                                        .font(FontToken.body)
                                        .foregroundColor(ColorToken.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "camera.viewfinder")
                                    .foregroundColor(ColorToken.accent)
                                    .font(.title2)
                            }
                            .padding(SpacingToken.large)
                        )
                        .padding(.horizontal, SpacingToken.large)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .background(ColorToken.background.ignoresSafeArea())
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .faceScan:
                    FaceScanView(viewModel: viewModel.makeFaceScanViewModel())
                }
            }
        }
    }
}

#Preview {
    HomeView(
        viewModel: HomeViewModel(
            appRouter: AppRouter(),
            faceScanService: FaceScanSessionService()
        )
    )
    .environmentObject(AppRouter())
}
