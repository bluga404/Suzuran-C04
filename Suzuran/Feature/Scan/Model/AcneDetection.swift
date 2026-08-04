import Foundation

struct AcneDetection: Identifiable {
    let id = UUID()
    let classIndex: Int
    let label: String
    let confidence: Double
    let box: CGRect
}
