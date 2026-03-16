import SwiftUI

// MARK: - AppFonts

enum AppFonts {
    static let display = Font.system(size: 22, weight: .medium)
    static let title   = Font.system(size: 15, weight: .medium)
    static let body    = Font.system(size: 13, weight: .regular)
    static let mono    = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let eyebrow = Font.system(size: 10, weight: .medium)

    /// Eyebrow labels also require `.textCase(.uppercase)` and `.tracking(eyebrowTracking)` in Views.
    static let eyebrowTracking: CGFloat = 1.0
}
