import AppKit

// MARK: - SyntaxHighlighter

struct SyntaxHighlighter {

    /// The font used for all editor text.
    static let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

    /// Returns the NSColor for a given token kind.
    static func color(for kind: JSONTokenKind, isKey: Bool) -> NSColor {
        switch kind {
        case .string:
            return isKey ? AppColors.NS.jsonKey : AppColors.NS.jsonString
        case .number:
            return AppColors.NS.jsonNumber
        case .boolean:
            return AppColors.NS.jsonBoolean
        case .null:
            return AppColors.NS.jsonNull
        case .objectOpen, .objectClose, .arrayOpen, .arrayClose, .colon, .comma:
            return AppColors.NS.jsonPunctuation
        case .unknown:
            return AppColors.NS.errorText
        case .whitespace:
            return AppColors.NS.textPrimary
        }
    }

    /// Applies syntax highlighting to an NSTextStorage for the given tokens.
    /// Must be called on the main thread.
    static func apply(tokens: [JSONToken], to textStorage: NSTextStorage) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        guard fullRange.length > 0 else { return }

        textStorage.beginEditing()

        // Set base attributes
        textStorage.addAttributes([
            .font: font,
            .foregroundColor: AppColors.NS.textPrimary
        ], range: fullRange)

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
