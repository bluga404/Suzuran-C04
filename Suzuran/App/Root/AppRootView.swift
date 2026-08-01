import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var appContainer: AppContainer

    var body: some View {
        Group {
            switch appRouter.rootRoute {
            case .onboarding:
                OnboardingView(
                    viewModel: OnboardingViewModel(appRouter: appRouter)
                )
            case .home:
                HomeView(
                    viewModel: HomeViewModel(
                        appRouter: appRouter,
                        faceScanService: appContainer.faceScanService
                    )
                )
            }
        }
        .animation(.easeOut(duration: 0.22), value: appRouter.rootRoute)
        .background(ColorToken.background.ignoresSafeArea())
    }
}

#Preview {
    AppRootView()
        .environmentObject(AppRouter())
        .environmentObject(AppContainer())
}