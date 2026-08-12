import Foundation

/// Canonical representation of a skincare ingredient.
///
/// - `id`: Canonical_ID — the deterministic, normalized identifier used for matching
///   between user product ingredients and reference data (cosing.json, AcneIngredients.json).
/// - `name`: Display name shown in the UI (preserves original casing/spacing after trim).
/// - `normalizedName`: Equal to `id`. Retained as a distinct field for clarity when
///   consumers need the normalized form without treating it as an identifier.
///
/// Two raw strings that reduce to the same canonical form are considered the same
/// ingredient (Req 3.4, 7.1, 7.2). Use ``init(fromRawName:)`` to construct from any
/// raw source (OCR result, user input, legacy payload string).
///
/// - SeeAlso: ``canonicalize(_:)`` — the single source of truth for normalization.
struct IngredientReference: Codable, Hashable, Identifiable {
    let id: String              // Canonical_ID
    let name: String            // display name
    let normalizedName: String  // = id, retained for clarity/debug

    init(id: String, name: String, normalizedName: String) {
        self.id = id
        self.name = name
        self.normalizedName = normalizedName
    }

    /// Convenience initializer that derives the Canonical_ID from a raw display name.
    ///
    /// The `name` field preserves the original raw name (only leading/trailing whitespace
    /// trimmed) so the UI can render what the user typed. The `id` and `normalizedName`
    /// are computed via ``canonicalize(_:)``.
    init(fromRawName rawName: String) {
        let canonical = IngredientReference.canonicalize(rawName)
        self.id = canonical
        self.name = rawName.trimmingCharacters(in: .whitespaces)
        self.normalizedName = canonical
    }
}

extension IngredientReference {

    /// Single source of truth for Canonical_ID normalization (Req 3.3, 3.4).
    ///
    /// Steps (in order):
    /// 1. Lowercase the input.
    /// 2. Strip disallowed punctuation, keeping alphanumerics, whitespace, and `-`.
    /// 3. Collapse consecutive whitespace into a single space and trim ends.
    ///
    /// The function is deterministic and idempotent: `canonicalize(canonicalize(s)) == canonicalize(s)`.
    static func canonicalize(_ input: String) -> String {
        // 1. Lowercase
        let lower = input.lowercased()

        // 2. Keep only alphanumerics, whitespace, and hyphen. Strip everything else.
        let allowed = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-"))
        let filteredScalars = lower.unicodeScalars.filter { allowed.contains($0) }
        let filtered = String(String.UnicodeScalarView(filteredScalars))

        // 3. Collapse whitespace runs into single spaces and trim ends.
        let collapsed = filtered
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return collapsed
    }
}
