import Foundation

struct IngredientReference: Identifiable, Codable, Equatable, Hashable {
    let id: String // Canonical ID or exact string representation
    let name: String // Display name
    let normalizedName: String // Lowercased and trimmed name for internal matching
    
    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
        self.normalizedName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
