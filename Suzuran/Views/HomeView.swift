import SwiftUI
import PhotosUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Header
                        Text("AI Skin Analysis")
                            .font(.system(.largeTitle, design: .rounded).bold())
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        // Image Picker Area
                        imagePickerSection
                        
                        // Ingredients Input
                        LiquidGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Current Skincare:")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.white)
                                TextField("e.g. Panthenol, Niacinamide", text: $viewModel.ingredientsInput)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Button
                        TactileButton(
                            title: "Analyze with AI",
                            icon: "sparkles",
                            action: { viewModel.startAnalysis() },
                            isLoading: viewModel.isProcessing
                        )
                        .padding(.horizontal)
                        
                        // Status
                        if !viewModel.statusMessage.isEmpty {
                            Text(viewModel.statusMessage)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .animation(.easeInOut, value: viewModel.statusMessage)
                        }
                        
                        // Results Area
                        if viewModel.showResult, let insight = viewModel.insightResult {
                            InsightResultView(insight: insight, counts: viewModel.rawCounts ?? [:])
                                .padding(.horizontal)
                                .padding(.bottom, 40)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var imagePickerSection: some View {
        VStack(spacing: 16) {
            if let selectedImage = viewModel.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Theme.glassStroke, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
                    .padding(.horizontal)
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .frame(height: 280)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Theme.glassStroke, style: StrokeStyle(lineWidth: 1, dash: [10]))
                    )
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "face.dashed")
                                .font(.system(size: 40))
                            Text("Select a face photo")
                                .font(.system(.headline, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.6))
                    )
                    .padding(.horizontal)
            }
            
            PhotosPicker(selection: $viewModel.selectedItem, matching: .images, photoLibrary: .shared()) {
                Text(viewModel.selectedImage == nil ? "Choose Photo" : "Change Photo")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            }
        }
    }
}
