import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appRouter: AppRouter

    var body: some View {
        Group {
            switch appRouter.currentRoute {
            case .onboarding:
                OnboardingView(appRouter: appRouter)
            case .home:
                HomeView(viewModel: HomeViewModel())
            }
        }
        .animation(.easeOut(duration: 0.22), value: appRouter.currentRoute)
        .background(Color.suzuranBackground.ignoresSafeArea())
    }
}

#Preview {
    AppRootView()
        .environmentObject(AppRouter())
}