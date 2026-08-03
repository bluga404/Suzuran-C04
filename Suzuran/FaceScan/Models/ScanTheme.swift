//
//  ScanTheme.swift
//  Suzuran
//
//  Shared design tokens: accent colors and tick-mark geometry constants.
//  All symbols are internal so every file in the module can reference them.
//

import SwiftUI

// MARK: - Accent Colors

extension Color {
    /// Bright mint green — completed tick / badge accent.
    static let scanGreen   = Color(red: 0.20, green: 0.95, blue: 0.55)
    /// Slightly deeper emerald — gradient second stop.
    static let scanEmerald = Color(red: 0.05, green: 0.80, blue: 0.42)
    /// Inactive tick color.
    static let tickIdle    = Color.white.opacity(0.22)
}

// MARK: - Tick Geometry

/// Single source of truth for tick-mark dimensions.
/// Changing these values affects every `TickMark` instance simultaneously.
enum TickGeometry {
    // Idle (unvisited) state
    static let idleWidth:  CGFloat = 2.5
    static let idleHeight: CGFloat = 9.0

    // Completed (visited) state
    static let doneWidth:  CGFloat = 4.5
    static let doneHeight: CGFloat = 22.0
}
