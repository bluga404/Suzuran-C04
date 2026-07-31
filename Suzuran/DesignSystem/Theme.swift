import SwiftUI

struct Theme {
    static let primaryBackground = LinearGradient(
        colors: [
            Color(red: 0.1, green: 0.05, blue: 0.3),  // Deep Purple
            Color(red: 0.05, green: 0.15, blue: 0.4)  // Ocean Blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glassStroke = LinearGradient(
        colors: [.white.opacity(0.5), .clear, .white.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accent = Color(red: 0.4, green: 0.8, blue: 1.0)
    static let warning = Color(red: 1.0, green: 0.4, blue: 0.4)
}
