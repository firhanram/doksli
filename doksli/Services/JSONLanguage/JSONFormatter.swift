import Foundation

// MARK: - JSONFormatter

struct JSONFormatter {

    /// Pretty-prints JSON from a token stream, preserving exact source values.
    /// Returns nil if the input is empty or contains structural errors.
    static func prettyPrint(tokens: [JSONToken], source: String, indent: Int = 4) -> String? {
        let significant = tokens.filter { $0.kind != .whitespace }
        guard !significant.isEmpty else { return nil }

        // Single-token fragments (number, string, boolean, null) — return as-is
        if significant.count == 1 {
            let token = significant[0]
            switch token.kind {
            case .number, .string, .boolean, .null:
                return extractText(token.span, from: source)
            default:
                break
            }
        }

        // Check for structural validity (no unknown tokens, balanced braces)
        if significant.contains(where: { $0.kind == .unknown }) { return nil }
        if !isBalanced(significant) { return nil }

        let indentStr = String(repeating: " ", count: indent)
        var result = ""
        var depth = 0

        for (i, token) in significant.enumerated() {
            let text = extractText(token.span, from: source)

            switch token.kind {
            case .objectOpen, .arrayOpen:
                result += text
                // Check if next significant token is the matching close
                if i + 1 < significant.count &&
                    (significant[i + 1].kind == .objectClose || significant[i + 1].kind == .arrayClose) {
                    // Empty container — don't add newline
                } else {
                    depth += 1
                    result += "\n"
                    result += String(repeating: indentStr, count: depth)
                }

            case .objectClose, .arrayClose:
                // Check if previous significant token was the matching open
                if i > 0 &&
                    (significant[i - 1].kind == .objectOpen || significant[i - 1].kind == .arrayOpen) {
                    // Empty container — no indent
                } else {
                    depth -= 1
                    result += "\n"
                    result += String(repeating: indentStr, count: depth)
                }
                result += text

            case .comma:
                result += text
                result += "\n"
                result += String(repeating: indentStr, count: depth)

            case .colon:
                result += text
                result += " "

            default:
                result += text
            }
        }

        return result
    }

    /// Convenience: tokenize + format in one call.
    static func prettyPrint(_ string: String, indent: Int = 4) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var tokens = JSONTokenizer.tokenize(string)
        JSONTokenizer.markKeys(&tokens)
        return prettyPrint(tokens: tokens, source: string, indent: indent)
    }

    // MARK: - Private helpers

    private static func extractText(_ span: UTF16Span, from source: String) -> String {
        let utf16 = source.utf16
        let startIdx = utf16.index(utf16.startIndex, offsetBy: span.start)
        let endIdx = utf16.index(utf16.startIndex, offsetBy: span.end)
        return String(utf16[startIdx..<endIdx])!
    }

    private static func isBalanced(_ tokens: [JSONToken]) -> Bool {
        var depth = 0
        for token in tokens {
            switch token.kind {
            case .objectOpen, .arrayOpen: depth += 1
            case .objectClose, .arrayClose: depth -= 1
            default: break
            }
            if depth < 0 { return false }
        }
        return depth == 0
    }
}
