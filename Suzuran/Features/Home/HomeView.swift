import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.large) {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text(viewModel.greeting)
                        .font(Typography.title)
                        .foregroundColor(.suzuranTextPrimary)
                    Text(viewModel.details)
                        .font(Typography.body)
                        .foregroundColor(.suzuranTextSecondary)
                }
                .padding(.horizontal, Spacing.large)
                .padding(.top, Spacing.large)

                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .fill(Color.suzuranSurface)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 10)
                    .overlay(
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Today")
                                .font(Typography.heading)
                                .foregroundColor(.suzuranTextPrimary)
                            Text("You have 3 focus sessions ready to start.")
                                .font(Typography.body)
                                .foregroundColor(.suzuranTextSecondary)
                        }
                        .padding(Spacing.large)
                    )
                    .padding(.horizontal, Spacing.large)

                Spacer()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.suzuranBackground.ignoresSafeArea())
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}