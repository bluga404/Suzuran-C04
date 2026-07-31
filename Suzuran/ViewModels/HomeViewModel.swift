import SwiftUI
import PhotosUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem? = nil {
        didSet {
            loadTransferable(from: selectedItem)
        }
    }
    @Published var selectedImage: UIImage? = nil
    @Published var ingredientsInput: String = ""
    
    @Published var isProcessing = false
    @Published var statusMessage = "Silakan pilih foto dan isi ingredients."
    @Published var rawCounts: [String: Int]? = nil
    @Published var insightResult: InsightResponse? = nil
    @Published var showResult = false
    
    private let mlService = AcneMLService()
    private let llmService = GeminiRESTService()
    
    private func loadTransferable(from item: PhotosPickerItem?) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                self.selectedImage = uiImage
                self.resetState(message: "Foto siap dianalisis.")
            }
        }
    }
    
    private func resetState(message: String) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            self.insightResult = nil
            self.rawCounts = nil
            self.showResult = false
        }
        self.statusMessage = message
    }
    
    func startAnalysis() {
        guard let image = selectedImage else {
            statusMessage = "Pilih foto wajah terlebih dahulu."
            return
        }
        
        let ingredients = ingredientsInput.isEmpty ? "Tidak ada" : ingredientsInput
        isProcessing = true
        resetState(message: "CoreML sedang mendeteksi jerawat...")
        
        mlService.detectAcne(in: image) { [weak self] counts, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.statusMessage = "Error Vision/CoreML: \(error.localizedDescription)"
                    self.isProcessing = false
                    return
                }
                
                self.rawCounts = counts
                self.statusMessage = "Deteksi selesai! Memanggil Gemini..."
                
                // Mock score calculation for PoC
                let totalAcne = counts.values.reduce(0, +)
                let mockScore = max(0, 100 - (totalAcne * 5))
                
                self.llmService.generateInsight(scanScore: mockScore, acneCounts: counts, ingredients: ingredients) { result in
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        switch result {
                        case .success(let insight):
                            self.statusMessage = "Analisis berhasil."
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                self.insightResult = insight
                                self.showResult = true
                            }
                        case .failure(let err):
                            self.statusMessage = "Error Gemini: \(err.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
}
