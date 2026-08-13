import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "person.fill")
                .font(Font.system(size: 48, weight: .regular))
                .foregroundStyle(AppColor.accentPrimary)
            Text("Halo Profile")
                .font(Font.screenTitle)
                .foregroundStyle(.primary)
            Text("Profil pengguna akan segera hadir")
                .font(Font.description)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ProfileView()
}
