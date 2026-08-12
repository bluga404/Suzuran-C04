import SwiftUI

/// Design-system typography scale (SF Pro / system font).
///
/// Each token maps to a system text style so fonts scale with Dynamic Type
/// (accessibility). Static members are prefixed to avoid clashing with
/// SwiftUI's built-in `Font` styles (e.g. `Font.title`, `Font.body`).
extension Font {
    static let pageTitle     = Font.system(.largeTitle).weight(.bold)      // 34 pt — Page Title
    static let screenTitle   = Font.system(.title).weight(.bold)           // 28 pt — Screen Title
    static let sectionTitle  = Font.system(.title2).weight(.bold)          // 22 pt — Section Title
    static let cardTitle     = Font.system(.title3).weight(.semibold)      // 20 pt — Card Title
    static let bodyLarge     = Font.system(.headline).weight(.semibold)    // 17 pt — Body/Large
    static let bodyParagraph = Font.system(.body)                          // 17 pt — Body/Regular
    static let description   = Font.system(.callout).weight(.semibold)     // 16 pt — Body/Medium
    static let label         = Font.system(.subheadline).weight(.semibold) // 15 pt — Label
    static let metadata      = Font.system(.footnote).weight(.semibold)    // 13 pt — Label/Footnote
    static let metadataLight = Font.system(.footnote).weight(.light)       // 13 pt — Label/Footnote Light
    static let graphLabel    = Font.system(.caption).weight(.semibold)     // 12 pt — Caption
    static let helperText    = Font.system(.caption2).weight(.semibold)    // 11 pt — Caption/Small
}
