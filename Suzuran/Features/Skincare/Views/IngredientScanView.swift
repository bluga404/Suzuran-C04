import SwiftUI
import PhotosUI

struct IngredientScanView: View {
    @ObservedObject var viewModel: AddSkincareViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var isShowingCamera = false
    @State private var isShowingReview = false
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Spacer()
                
                // Explanatory Illustration/Icon
                VStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppColor.accentPrimary.opacity(0.08))
                            .frame(width: 140, height: 140)
                        
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 64))
                            .foregroundStyle(AppColor.accentPrimary)
                    }
                    
                    Text("Pindai Label Komposisi")
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.textPrimary)
                    
                    Text("Posisikan kamera tepat pada tulisan 'Ingredients' atau 'Komposisi' di botol/kemasan skincare Anda.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: AppSpacing.md) {
                    // Take Photo Button
                    Button(action: {
                        isShowingCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Ambil Foto Label")
                                .font(AppTypography.bodyBold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColor.accentPrimary)
                        .foregroundStyle(AppColor.textOnAccent)
                        .cornerRadius(AppCornerRadius.md)
                    }
                    
                    // Choose from Library
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Pilih dari Galeri")
                                .font(AppTypography.bodyBold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColor.surfacePrimary)
                        .foregroundStyle(AppColor.accentPrimary)
                        .cornerRadius(AppCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                .stroke(AppColor.accentPrimary, lineWidth: 1.5)
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColor.backgroundPrimary)
            .navigationTitle("Scan Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.accentPrimary)
                }
            }
            // Camera Sheet
            .sheet(isPresented: $isShowingCamera) {
                CameraPicker(selectedImage: $selectedImage)
            }
            // Listen for image selection (either Camera or Library)
            .onChange(of: selectedImage) { _, image in
                if let image = image {
                    triggerOCR(image: image)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                        }
                    }
                }
            }
            // Loading and Navigation Overlay
            .overlay {
                if viewModel.isProcessingOCR {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: AppSpacing.sm) {
                            ProgressView()
                                .tint(.white)
                            Text("Membaca teks komposisi...")
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(.white)
                        }
                        .padding(AppSpacing.lg)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(AppCornerRadius.md)
                    }
                }
            }
            // Navigate to Review View when scanned ingredients are ready
            .navigationDestination(isPresented: $isShowingReview) {
                IngredientReviewView(viewModel: viewModel) {
                    // On Save Action: dismiss scanner back to AddSkincareView
                    dismiss()
                }
            }
        }
    }

    private func triggerOCR(image: UIImage) {
        Task {
            await viewModel.processImageForOCR(image)
            isShowingReview = true
        }
    }
}
