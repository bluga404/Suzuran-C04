import SwiftUI

struct EmptySkincareView: View {
    let onAddSkincare: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("Skincare")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                
                Spacer(minLength: 120)
                
                VStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppColor.accentPrimary.opacity(0.05))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "bubbles.and.sparkles.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColor.accentPrimary)
                    }
                    
                    Text("No Skincare Routine Saved Yet")
                        .font(AppTypography.subtitle)
                        .foregroundStyle(AppColor.textSecondary)
                    
                    Button(action: onAddSkincare) {
                        Text("Add Skincare Routine")
                            .font(AppTypography.bodyBold)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColor.accentPrimary)
                            .foregroundStyle(.white)
                            .cornerRadius(AppCornerRadius.md)
                    }
                    .padding(.top, AppSpacing.sm)
                }
                .frame(maxWidth: .infinity)
                
                Spacer(minLength: 120)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
