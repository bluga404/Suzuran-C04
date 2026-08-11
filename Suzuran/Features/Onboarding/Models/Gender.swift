import Foundation

/// Gender option for avatar visualization selection.
enum Gender: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"

    var id: String { rawValue }
}
