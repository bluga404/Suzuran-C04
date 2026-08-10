import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "person.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.accentPrimary)
            Text("Halo Report")
                .font(AppTypography.title)
                .foregroundStyle(.primary)
            Text("Profil pengguna akan segera hadir")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ProfileView()
}
