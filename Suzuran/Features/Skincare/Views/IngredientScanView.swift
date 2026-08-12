import SwiftUI
import PhotosUI

struct IngredientScanView: View {
    @ObservedObject var viewModel: AddSkincareViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var isShowingCamera = false
    @State private var isShowingInstruction = false
    @State private var selectedImage: UIImage?

    /// First-time auto-present flag store (Req 11.5).
    private let kvStore: KeyValueStore = UserDefaultsKeyValueStore(userDefaults: .standard)
    private let hasSeenInstructionKey = "suzuran.skincare.hasSeenScanInstructionModal"

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

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
                        .font(Font.screenTitle)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Posisikan kamera tepat pada tulisan 'Ingredients' atau 'Komposisi' di botol/kemasan skincare Anda.")
                        .font(Font.description)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }

                Spacer()

                VStack(spacing: AppSpacing.md) {
                    Button(action: { isShowingCamera = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Ambil Foto Label")
                                .font(Font.description)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColor.accentPrimary)
                        .foregroundStyle(AppColor.textOnAccent)
                        .cornerRadius(AppCornerRadius.md)
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Pilih dari Galeri")
                                .font(Font.description)
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
                    Button("Batal") { dismiss() }
                        .font(Font.description)
                        .foregroundStyle(AppColor.accentPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingInstruction = true }) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(AppColor.accentPrimary)
                    }
                    .accessibilityLabel(Text("Cara scan ingredient"))
                }
            }
            .sheet(isPresented: $isShowingCamera) {
                CameraPicker(selectedImage: $selectedImage)
            }
            .fullScreenCover(isPresented: $isShowingInstruction) {
                ScanInstructionModalView(onDismiss: { isShowingInstruction = false })
            }
            .onChange(of: selectedImage) { _, image in
                if let image = image {
                    triggerOCR(image: image)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run { selectedImage = image }
                    }
                }
            }
            .overlay {
                if viewModel.isScanning {
                    ZStack {
                        AppColor.backgroundPrimary.opacity(0.8)
                            .ignoresSafeArea()

                        VStack(spacing: AppSpacing.sm) {
                            ProgressView()
                                .tint(AppColor.accentPrimary)
                            Text("Membaca teks komposisi...")
                                .font(Font.description)
                                .foregroundStyle(AppColor.textPrimary)
                        }
                        .padding(AppSpacing.lg)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
                    }
                }
            }
            .alert(
                "Gagal Memindai",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                // Auto-present the instruction modal on first launch of the scanner (Req 11.5).
                if !kvStore.bool(forKey: hasSeenInstructionKey) {
                    isShowingInstruction = true
                    kvStore.set(true, forKey: hasSeenInstructionKey)
                }
            }
        }
    }

    private func triggerOCR(image: UIImage) {
        Task {
            await viewModel.processImage(image)
            // Return to the Add form so OCR candidates can be reviewed beside the
            // product fields, matching the mockup's continuous add flow.
            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }
}
