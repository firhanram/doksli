import Foundation

// MARK: - JSONTokenizer

struct JSONTokenizer {

    /// Tokenizes a JSON string into a flat array of tokens.
    /// All offsets are UTF-16 code unit positions. Never throws — invalid
    /// input produces `.unknown` tokens for error recovery.
    static func tokenize(_ string: String) -> [JSONToken] {
        let utf16 = Array(string.utf16)
        let count = utf16.count
        var tokens: [JSONToken] = []
        var i = 0

        while i < count {
            let cu = utf16[i]

            switch cu {
            case 0x7B: // {
                tokens.append(JSONToken(kind: .objectOpen, span: UTF16Span(start: i, end: i + 1)))
                i += 1
            case 0x7D: // }
                tokens.append(JSONToken(kind: .objectClose, span: UTF16Span(start: i, end: i + 1)))
                i += 1
            case 0x5B: // [
                tokens.append(JSONToken(kind: .arrayOpen, span: UTF16Span(start: i, end: i + 1)))
                i += 1
            case 0x5D: // ]
                tokens.append(JSONToken(kind: .arrayClose, span: UTF16Span(start: i, end: i + 1)))
                i += 1
            case 0x3A: // :
                tokens.append(JSONToken(kind: .colon, span: UTF16Span(start: i, end: i + 1)))
                i += 1
            case 0x2C: // ,
                tokens.append(JSONToken(kind: .comma, span: UTF16Span(start: i, end: i + 1)))
                i += 1
            case 0x22: // "
                let token = scanString(utf16, from: i)
                tokens.append(token)
                i = token.span.end
            case 0x20, 0x09, 0x0A, 0x0D: // space, tab, LF, CR
                let token = scanWhitespace(utf16, from: i)
                tokens.append(token)
                i = token.span.end
            case 0x74: // t — true
                let token = scanKeyword(utf16, from: i, expected: kTrue, kind: .boolean)
                tokens.append(token)
                i = token.span.end
            case 0x66: // f — false
                let token = scanKeyword(utf16, from: i, expected: kFalse, kind: .boolean)
                tokens.append(token)
                i = token.span.end
            case 0x6E: // n — null
                let token = scanKeyword(utf16, from: i, expected: kNull, kind: .null)
                tokens.append(token)
                i = token.span.end
            case 0x30...0x39, 0x2D: // 0-9, -
                let token = scanNumber(utf16, from: i)
                tokens.append(token)
                i = token.span.end
            default:
                tokens.append(JSONToken(kind: .unknown, span: UTF16Span(start: i, end: i + 1)))
                i += 1
            }
        }

        return tokens
    }

    /// Marks string tokens that are object keys.
    /// A string token is a key if the next non-whitespace token is `.colon`.
    static func markKeys(_ tokens: inout [JSONToken]) {
        for idx in tokens.indices {
            guard tokens[idx].kind == .string else { continue }
            // Look ahead past whitespace
            var j = idx + 1
            while j < tokens.count && tokens[j].kind == .whitespace { j += 1 }
            if j < tokens.count && tokens[j].kind == .colon {
                tokens[idx].isKey = true
            }
        }
    }

    // MARK: - Private scanners

    private static let kTrue: [UInt16]  = [0x74, 0x72, 0x75, 0x65]           // true
    private static let kFalse: [UInt16] = [0x66, 0x61, 0x6C, 0x73, 0x65]     // false
    private static let kNull: [UInt16]  = [0x6E, 0x75, 0x6C, 0x6C]           // null

    /// Scans a string token starting at the opening `"`.
    private static func scanString(_ utf16: [UInt16], from start: Int) -> JSONToken {
        var i = start + 1 // skip opening quote
        let count = utf16.count

        while i < count {
            let cu = utf16[i]
            if cu == 0x5C { // backslash
                i += 2 // skip escaped character
            } else if cu == 0x22 { // closing "
                return JSONToken(kind: .string, span: UTF16Span(start: start, end: i + 1))
            } else {
                i += 1
            }
        }

        // Unterminated string — span covers to end of input
        return JSONToken(kind: .string, span: UTF16Span(start: start, end: count))
    }

    /// Scans contiguous whitespace.
    private static func scanWhitespace(_ utf16: [UInt16], from start: Int) -> JSONToken {
        var i = start + 1
        let count = utf16.count
        while i < count {
            let cu = utf16[i]
            if cu == 0x20 || cu == 0x09 || cu == 0x0A || cu == 0x0D {
                i += 1
            } else {
                break
            }
        }
        return JSONToken(kind: .whitespace, span: UTF16Span(start: start, end: i))
    }

    /// Scans a keyword (true, false, null). Falls back to `.unknown` if mismatch.
    private static func scanKeyword(_ utf16: [UInt16], from start: Int,
                                    expected: [UInt16], kind: JSONTokenKind) -> JSONToken {
        let count = utf16.count
        let end = start + expected.count
        guard end <= count else {
            // Not enough characters — emit as unknown
            return JSONToken(kind: .unknown, span: UTF16Span(start: start, end: count))
        }
        for j in 0..<expected.count {
            if utf16[start + j] != expected[j] {
                return JSONToken(kind: .unknown, span: UTF16Span(start: start, end: start + 1))
            }
        }
        return JSONToken(kind: kind, span: UTF16Span(start: start, end: end))
    }

    /// Scans a number: optional `-`, digits, optional `.` + digits, optional `e`/`E` + optional sign + digits.
    private static func scanNumber(_ utf16: [UInt16], from start: Int) -> JSONToken {
        var i = start
        let count = utf16.count

        // Optional minus
        if i < count && utf16[i] == 0x2D { i += 1 } // -

        // Integer part
        let intStart = i
        while i < count && utf16[i] >= 0x30 && utf16[i] <= 0x39 { i += 1 } // 0-9

        // Lone minus with no digits
        if i == intStart && start < i {
            return JSONToken(kind: .unknown, span: UTF16Span(start: start, end: i))
        }

        // Fractional part
        if i < count && utf16[i] == 0x2E { // .
            i += 1
            while i < count && utf16[i] >= 0x30 && utf16[i] <= 0x39 { i += 1 }
        }

        // Exponent part
        if i < count && (utf16[i] == 0x65 || utf16[i] == 0x45) { // e, E
            i += 1
            if i < count && (utf16[i] == 0x2B || utf16[i] == 0x2D) { i += 1 } // +, -
            while i < count && utf16[i] >= 0x30 && utf16[i] <= 0x39 { i += 1 }
        }

        // Must have consumed at least one character beyond start
        if i == start {
            return JSONToken(kind: .unknown, span: UTF16Span(start: start, end: start + 1))
        }

        return JSONToken(kind: .number, span: UTF16Span(start: start, end: i))
    }
}
