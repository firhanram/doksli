import AppKit

// MARK: - SyntaxHighlighter

struct SyntaxHighlighter {

    /// The font used for all editor text.
    static let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

    /// Cached base attributes — avoids dictionary allocation on every apply() call.
    private static let baseAttributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: AppColors.NS.textPrimary
    ]

    /// Cached color table — avoids switch dispatch per token.
    private static let colorTable: [JSONTokenKind: NSColor] = [
        .string: AppColors.NS.jsonString,
        .number: AppColors.NS.jsonNumber,
        .boolean: AppColors.NS.jsonBoolean,
        .null: AppColors.NS.jsonNull,
        .objectOpen: AppColors.NS.jsonPunctuation,
        .objectClose: AppColors.NS.jsonPunctuation,
        .arrayOpen: AppColors.NS.jsonPunctuation,
        .arrayClose: AppColors.NS.jsonPunctuation,
        .colon: AppColors.NS.jsonPunctuation,
        .comma: AppColors.NS.jsonPunctuation,
        .unknown: AppColors.NS.errorText,
        .whitespace: AppColors.NS.textPrimary,
    ]
    private static let jsonKeyColor = AppColors.NS.jsonKey

    /// Returns the NSColor for a given token kind.
    static func color(for kind: JSONTokenKind, isKey: Bool) -> NSColor {
        if kind == .string && isKey { return jsonKeyColor }
        return colorTable[kind] ?? AppColors.NS.textPrimary
    }

    /// Applies syntax highlighting to an NSTextStorage for the given tokens.
    /// Must be called on the main thread.
    static func apply(tokens: [JSONToken], to textStorage: NSTextStorage) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        guard fullRange.length > 0 else { return }

        textStorage.beginEditing()

        // Set base attributes (cached dictionary — no allocation)
        textStorage.addAttributes(baseAttributes, range: fullRange)

        // Apply per-token colors
        for token in tokens {
            let nsRange = token.span.nsRange
            guard nsRange.location + nsRange.length <= textStorage.length else { continue }
            let tokenColor = color(for: token.kind, isKey: token.isKey)
            textStorage.addAttribute(.foregroundColor, value: tokenColor, range: nsRange)
        }

        textStorage.endEditing()
    }
}
