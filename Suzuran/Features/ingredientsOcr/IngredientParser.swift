//
//  IngredientParser.swift
//  IngredientOCR
//
//  Created by Dinda Putri Pamungkas  on 02/08/26.
//

import Foundation
struct IngredientParser {
    static func extractIngredients(from rawText: String) -> [String] {
        let normalized = rawText
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "•", with: ",")
            .replacingOccurrences(of: ";", with: ",")

        let lower = normalized.lowercased()

        let startKeywords = [
            "ingredients:",
            "ingredients",
            "ingredient list:",
            "composition:",
            "komposisi:"
        ]

        var ingredientText = normalized

        for keyword in startKeywords {
            if let range = lower.range(of: keyword) {
                ingredientText = String(normalized[range.upperBound...])
                break
            }
        }

        let stopKeywords = [
            "directions",
            "warning",
            "warnings",
            "how to use",
            "made in",
            "distributed by",
            "manufactured by",
            "."
        ]

        let lowerIngredientText = ingredientText.lowercased()

        for stop in stopKeywords {
            if let range = lowerIngredientText.range(of: stop) {
                ingredientText = String(ingredientText[..<range.lowerBound])
                break
            }
        }

        return ingredientText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 1 }
    }
}
