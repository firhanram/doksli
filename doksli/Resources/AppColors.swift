import SwiftUI

// MARK: - AppColors

enum AppColors {

    // MARK: Neutral surfaces

    static let canvas      = Color(hex: "#FDFCFA")
    static let surface     = Color(hex: "#F7F5F0")
    static let surfacePlus = Color(hex: "#F2EFE9")
    static let subtle      = Color(hex: "#EAE8E3")
    static let border      = Color(hex: "#DDD9D2")
    static let muted       = Color(hex: "#C8C4BC")

    // MARK: Text scale

    static let textPrimary     = Color(hex: "#1A1916")
    static let textSecondary   = Color(hex: "#3B3A37")
    static let textTertiary    = Color(hex: "#6B6760")
    static let textPlaceholder = Color(hex: "#8C8982")
    static let textFaint       = Color(hex: "#A09D96")

    // MARK: Brand accent

    static let brandTint50  = Color(hex: "#FAF0EA")
    static let brandTint100 = Color(hex: "#EECFBA")
    static let brand        = Color(hex: "#D4622E")
    static let brandHover   = Color(hex: "#C96A2A")
    static let brandPressed = Color(hex: "#A84E1E")

    // MARK: Semantic — backgrounds

    static let successBg = Color(hex: "#EAF5EE")
    static let infoBg    = Color(hex: "#EBF3FB")
    static let warningBg = Color(hex: "#FEF4E6")
    static let errorBg   = Color(hex: "#FDEEEC")

    // MARK: Semantic — text

    static let successText = Color(hex: "#1D6B3A")
    static let infoText    = Color(hex: "#1E5F8F")
    static let warningText = Color(hex: "#8A5A0B")
    static let errorText   = Color(hex: "#9B2A1E")

    // MARK: HTTP method colors

    static let methodGet     = MethodColor(bg: Color(hex: "#EAF5EE"), text: Color(hex: "#1D6B3A"))
    static let methodPost    = MethodColor(bg: Color(hex: "#EBF3FB"), text: Color(hex: "#1E5F8F"))
    static let methodPut     = MethodColor(bg: Color(hex: "#FEF4E6"), text: Color(hex: "#8A5A0B"))
    static let methodDelete  = MethodColor(bg: Color(hex: "#FDEEEC"), text: Color(hex: "#9B2A1E"))
    static let methodPatch   = MethodColor(bg: Color(hex: "#F0EBF8"), text: Color(hex: "#6040A0"))
    static let methodOptions = MethodColor(bg: Color(hex: "#E8F6F5"), text: Color(hex: "#1A5F5A"))
    static let methodHead    = MethodColor(bg: Color(hex: "#F2EFE9"), text: Color(hex: "#6B6760"))

    // MARK: JSON syntax colors

    static let jsonKey         = Color(hex: "#C96A2A")
    static let jsonString      = Color(hex: "#2D7F4E")
    static let jsonNumber      = Color(hex: "#6040A0")
    static let jsonBoolean     = Color(hex: "#1E5F8F")
    static let jsonNull        = Color(hex: "#8C8982")
    static let jsonPunctuation = Color(hex: "#6B6760")
}

// MARK: - MethodColor

struct MethodColor {
    let bg: Color
    let text: Color
}

// MARK: - Color hex initializer (private — only AppColors uses this)

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
