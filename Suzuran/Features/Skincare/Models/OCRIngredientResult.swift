import Foundation

struct OCRIngredientResult: Identifiable, Equatable, Hashable {
    let id: UUID
    let rawText: String
    
    init(id: UUID = UUID(), rawText: String) {
        self.id = id
        self.rawText = rawText
    }
}
