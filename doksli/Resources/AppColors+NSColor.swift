import AppKit

// MARK: - AppColors NSColor equivalents

extension AppColors {

    /// NSColor equivalents of AppColors tokens for use with NSTextStorage attributes.
    /// Hex values match design-system.md — duplicated (not converted from SwiftUI Color).
    enum NS {
        // JSON syntax
        static let jsonKey         = NSColor(hex: "#C96A2A")
        static let jsonString      = NSColor(hex: "#2D7F4E")
        static let jsonNumber      = NSColor(hex: "#6040A0")
        static let jsonBoolean     = NSColor(hex: "#1E5F8F")
        static let jsonNull        = NSColor(hex: "#8C8982")
        static let jsonPunctuation = NSColor(hex: "#6B6760")

        // Text scale
        static let textPrimary     = NSColor(hex: "#1A1916")
        static let textFaint       = NSColor(hex: "#A09D96")

        // Semantic
        static let errorText       = NSColor(hex: "#9B2A1E")
        static let warningText     = NSColor(hex: "#8A5A0B")

        // Surfaces
        static let surfacePlus     = NSColor(hex: "#F2EFE9")
        static let canvas          = NSColor(hex: "#FDFCFA")
        static let border          = NSColor(hex: "#DDD9D2")
    }
}

// MARK: - NSColor hex initializer

private extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8)  & 0xFF) / 255
        let b = CGFloat(int         & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
