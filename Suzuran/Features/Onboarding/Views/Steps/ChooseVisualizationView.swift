import SwiftUI

/// Avatar selection page: "Choose Your Visualization" (Image 5)
struct ChooseVisualizationView: View {
    @Binding var selectedGender: Gender
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.black)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer(minLength: 16)

            // Header Section
            VStack(spacing: 12) {
                Text("Choose Your Visualization")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                Text("Select the avatar you'd like to use for your illustrations and personalized reports.")
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 32)

            // Avatar Options (Male & Female Cards)
            VStack(spacing: 16) {
                avatarCard(
                    gender: .male,
                    iconName: "person",
                    isSelected: selectedGender == .male
                ) {
                    selectedGender = .male
                }

                avatarCard(
                    gender: .female,
                    iconName: "person.fill",
                    isSelected: selectedGender == .female
                ) {
                    selectedGender = .female
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Bottom Action Button
            Button(action: onNext) {
                Text("Next")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(Color(white: 0.6))
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: - Avatar Card Component

    private func avatarCard(
        gender: Gender,
        iconName: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(.black)

                Text(gender.rawValue)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(height: 84)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.gray : Color.clear, lineWidth: 2)
                    .padding(1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color(white: 0.7) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChooseVisualizationView(
        selectedGender: .constant(.female),
        onNext: {},
        onBack: {}
    )
}
