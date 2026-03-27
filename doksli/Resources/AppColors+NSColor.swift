import AppKit

// MARK: - AppColors NSColor equivalents

extension AppColors {

    /// NSColor equivalents of AppColors tokens for use with NSTextStorage attributes.
    /// Uses dynamic provider to resolve light/dark at draw time.
    enum NS {
        // JSON syntax
        static let jsonKey         = adaptive(light: "#C96A2A", dark: "#D4916A")
        static let jsonString      = adaptive(light: "#2D7F4E", dark: "#4CAF50")
        static let jsonNumber      = adaptive(light: "#6040A0", dark: "#AB47BC")
        static let jsonBoolean     = adaptive(light: "#1E5F8F", dark: "#42A5F5")
        static let jsonNull        = adaptive(light: "#8C8982", dark: "#6A6158")
        static let jsonPunctuation = adaptive(light: "#6B6760", dark: "#9A9389")

        // Text scale
        static let textPrimary     = adaptive(light: "#1A1916", dark: "#E8E6E3")
        static let textFaint       = adaptive(light: "#A09D96", dark: "#5A5549")

        // Semantic
        static let errorText       = adaptive(light: "#9B2A1E", dark: "#FF6B6B")
        static let warningText     = adaptive(light: "#8A5A0B", dark: "#F3DF31")

        // Surfaces
        static let surfacePlus     = adaptive(light: "#F2EFE9", dark: "#2A251D")
        static let canvas          = adaptive(light: "#FDFCFA", dark: "#1A1815")
        static let border          = adaptive(light: "#DDD9D2", dark: "#3A352B")

        private static func adaptive(light: String, dark: String) -> NSColor {
            NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                return isDark ? NSColor(adaptiveHex: dark) : NSColor(adaptiveHex: light)
            }
        }
    }
}
