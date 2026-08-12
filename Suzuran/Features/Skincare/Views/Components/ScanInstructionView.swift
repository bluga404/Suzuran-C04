import SwiftUI

struct ScanInstructionView: View {
    @Environment(\.dismiss) private var dismiss
    let onStartScan: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 80))
                        .foregroundStyle(AppColor.accentPrimary)
                        .padding(.top, AppSpacing.xl)
                    
                    VStack(spacing: AppSpacing.sm) {
                        Text("Scan Kandungan Skincare")
                            .font(AppTypography.title)
                            .foregroundStyle(AppColor.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Arahkan kamera ke bagian komposisi (ingredients) pada kemasan produk skincare Anda.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        instructionRow(
                            icon: "text.alignleft",
                            title: "Pastikan teks jelas",
                            subtitle: "Cari pencahayaan yang terang agar teks mudah dibaca."
                        )
                        
                        instructionRow(
                            icon: "viewfinder",
                            title: "Fokus pada Ingredients",
                            subtitle: "Posisikan teks komposisi di tengah layar."
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    Spacer(minLength: 40)
                    
                }
            }
            .background(AppColor.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
    
    private func instructionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(AppColor.accentPrimary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}
