//
//  Ingredient.swift
//  Suzuran
//
//  Created by Dinda Putri Pamungkas  on 10/08/26.
//

import Foundation

struct Ingredient: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let aliases: [String]
}
