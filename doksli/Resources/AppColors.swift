import AppKit
import SwiftUI

// MARK: - AppColors

enum AppColors {

    // MARK: Neutral surfaces

    static let canvas      = adaptive(light: "#FDFCFA", dark: "#1A1815")
    static let surface     = adaptive(light: "#F7F5F0", dark: "#201D18")
    static let surfacePlus = adaptive(light: "#F2EFE9", dark: "#2A251D")
    static let subtle      = adaptive(light: "#EAE8E3", dark: "#3A352B")
    static let border      = adaptive(light: "#DDD9D2", dark: "#3A352B")
    static let muted       = adaptive(light: "#C8C4BC", dark: "#6A6158")

    // MARK: Text scale

    static let textPrimary     = adaptive(light: "#1A1916", dark: "#E8E6E3")
    static let textSecondary   = adaptive(light: "#3B3A37", dark: "#C4BEB5")
    static let textTertiary    = adaptive(light: "#6B6760", dark: "#9A9389")
    static let textPlaceholder = adaptive(light: "#8C8982", dark: "#6A6158")
    static let textFaint       = adaptive(light: "#A09D96", dark: "#5A5549")

    // MARK: Brand accent

    static let brandTint50  = adaptive(light: "#FAF0EA", dark: "#2A2018")
    static let brandTint100 = adaptive(light: "#EECFBA", dark: "#3A2A1A")
    static let brand        = adaptive(light: "#D4622E", dark: "#D4622E")
    static let brandHover   = adaptive(light: "#C96A2A", dark: "#E67D22")
    static let brandPressed = adaptive(light: "#A84E1E", dark: "#C96A2A")

    // MARK: Semantic — backgrounds

    static let successBg = adaptive(light: "#EAF5EE", dark: "#1A2E20")
    static let infoBg    = adaptive(light: "#EBF3FB", dark: "#1A2535")
    static let warningBg = adaptive(light: "#FEF4E6", dark: "#2E2510")
    static let errorBg   = adaptive(light: "#FDEEEC", dark: "#2E1A18")

    // MARK: Semantic — text

    static let successText = adaptive(light: "#1D6B3A", dark: "#4CAF50")
    static let infoText    = adaptive(light: "#1E5F8F", dark: "#42A5F5")
    static let warningText = adaptive(light: "#8A5A0B", dark: "#F3DF31")
    static let errorText   = adaptive(light: "#9B2A1E", dark: "#FF6B6B")

    // MARK: HTTP method colors

    static let methodGet = MethodColor(
        bg: adaptive(light: "#EAF5EE", dark: "#1A2E20"),
        text: adaptive(light: "#1D6B3A", dark: "#4CAF50")
    )
    static let methodPost = MethodColor(
        bg: adaptive(light: "#EBF3FB", dark: "#1A2535"),
        text: adaptive(light: "#1E5F8F", dark: "#42A5F5")
    )
    static let methodPut = MethodColor(
        bg: adaptive(light: "#FEF4E6", dark: "#2E2510"),
        text: adaptive(light: "#8A5A0B", dark: "#F3DF31")
    )
    static let methodDelete = MethodColor(
        bg: adaptive(light: "#FDEEEC", dark: "#2E1A18"),
        text: adaptive(light: "#9B2A1E", dark: "#FF6B6B")
    )
    static let methodPatch = MethodColor(
        bg: adaptive(light: "#F0EBF8", dark: "#251A30"),
        text: adaptive(light: "#6040A0", dark: "#AB47BC")
    )
    static let methodOptions = MethodColor(
        bg: adaptive(light: "#E8F6F5", dark: "#1A2E2D"),
        text: adaptive(light: "#1A5F5A", dark: "#26C6DA")
    )
    static let methodHead = MethodColor(
        bg: adaptive(light: "#F2EFE9", dark: "#2A251D"),
        text: adaptive(light: "#6B6760", dark: "#9A9389")
    )

    // MARK: Search highlighting

    static let searchHighlight       = adaptive(light: "#FAF0EA", dark: "#2A2018")
    static let searchHighlightActive = adaptive(light: "#EECFBA", dark: "#3A2A1A")

    // MARK: JSON syntax colors

    static let jsonKey         = adaptive(light: "#C96A2A", dark: "#D4916A")
    static let jsonString      = adaptive(light: "#2D7F4E", dark: "#4CAF50")
    static let jsonNumber      = adaptive(light: "#6040A0", dark: "#AB47BC")
    static let jsonBoolean     = adaptive(light: "#1E5F8F", dark: "#42A5F5")
    static let jsonNull        = adaptive(light: "#8C8982", dark: "#6A6158")
    static let jsonPunctuation = adaptive(light: "#6B6760", dark: "#9A9389")

    // MARK: - Adaptive helper

    private static func adaptive(light: String, dark: String) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(adaptiveHex: dark) : NSColor(adaptiveHex: light)
        })
    }
}

// MARK: - MethodColor

struct MethodColor {
    let bg: Color
    let text: Color
}

// MARK: - NSColor hex initializer (shared with AppColors+NSColor.swift)

extension NSColor {
    convenience init(adaptiveHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8)  & 0xFF) / 255
        let b = CGFloat(int         & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
