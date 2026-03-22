import Foundation

// MARK: - DiagnosticSeverity

enum DiagnosticSeverity: Equatable {
    case error
    case warning
    case hint
}

// MARK: - JSONDiagnostic

struct JSONDiagnostic: Equatable {
    let severity: DiagnosticSeverity
    let message: String
    let span: UTF16Span
}

// MARK: - JSONLinter

struct JSONLinter {

    /// Runs all lint checks on a token stream and returns diagnostics.
    /// The source string is needed for extracting key text (duplicate check).
    static func lint(tokens: [JSONToken], source: String) -> [JSONDiagnostic] {
        var diagnostics: [JSONDiagnostic] = []
        checkUnknownTokens(tokens, into: &diagnostics)
        checkStructuralErrors(tokens, into: &diagnostics)
        checkTrailingCommas(tokens, into: &diagnostics)
        checkDuplicateKeys(tokens, source: source, into: &diagnostics)
        return diagnostics
    }

    // MARK: - Unknown tokens

    private static func checkUnknownTokens(_ tokens: [JSONToken],
                                           into diagnostics: inout [JSONDiagnostic]) {
        for token in tokens where token.kind == .unknown {
            diagnostics.append(JSONDiagnostic(
                severity: .error,
                message: "Unexpected character",
                span: token.span
            ))
        }
    }

    // MARK: - Structural errors (mismatched braces/brackets)

    private static func checkStructuralErrors(_ tokens: [JSONToken],
                                              into diagnostics: inout [JSONDiagnostic]) {
        struct Opener {
            let kind: JSONTokenKind  // objectOpen or arrayOpen
            let span: UTF16Span
        }

        var stack: [Opener] = []

        for token in tokens {
            switch token.kind {
            case .objectOpen:
                stack.append(Opener(kind: .objectOpen, span: token.span))
            case .arrayOpen:
                stack.append(Opener(kind: .arrayOpen, span: token.span))
            case .objectClose:
                if let last = stack.last, last.kind == .objectOpen {
                    stack.removeLast()
                } else if let last = stack.last, last.kind == .arrayOpen {
                    diagnostics.append(JSONDiagnostic(
                        severity: .error,
                        message: "Expected ']' but found '}'",
                        span: token.span
                    ))
                    stack.removeLast()
                } else {
                    diagnostics.append(JSONDiagnostic(
                        severity: .error,
                        message: "Unexpected '}'",
                        span: token.span
                    ))
                }
            case .arrayClose:
                if let last = stack.last, last.kind == .arrayOpen {
                    stack.removeLast()
                } else if let last = stack.last, last.kind == .objectOpen {
                    diagnostics.append(JSONDiagnostic(
                        severity: .error,
                        message: "Expected '}' but found ']'",
                        span: token.span
                    ))
                    stack.removeLast()
                } else {
                    diagnostics.append(JSONDiagnostic(
                        severity: .error,
                        message: "Unexpected ']'",
                        span: token.span
                    ))
                }
            default:
                break
            }
        }

        // Unclosed openers
        for opener in stack {
            let expected: Character = opener.kind == .objectOpen ? "}" : "]"
            diagnostics.append(JSONDiagnostic(
                severity: .error,
                message: "Unclosed '\(opener.kind == .objectOpen ? "{" : "[")' — expected '\(expected)'",
                span: opener.span
            ))
        }
    }

    // MARK: - Trailing commas

    private static func checkTrailingCommas(_ tokens: [JSONToken],
                                            into diagnostics: inout [JSONDiagnostic]) {
        let significant = tokens.filter { $0.kind != .whitespace }
        for i in 0..<significant.count {
            guard significant[i].kind == .comma else { continue }
            if i + 1 < significant.count {
                let next = significant[i + 1]
                if next.kind == .objectClose || next.kind == .arrayClose {
                    diagnostics.append(JSONDiagnostic(
                        severity: .error,
                        message: "Trailing comma before '\(next.kind == .objectClose ? "}" : "]")'",
                        span: significant[i].span
                    ))
                }
            }
        }
    }

    // MARK: - Duplicate keys

    private static func checkDuplicateKeys(_ tokens: [JSONToken], source: String,
                                           into diagnostics: inout [JSONDiagnostic]) {
        let utf16 = Array(source.utf16)
        var scopeStack: [Set<String>] = []

        for token in tokens {
            switch token.kind {
            case .objectOpen:
                scopeStack.append(Set<String>())
            case .objectClose:
                if !scopeStack.isEmpty { scopeStack.removeLast() }
            case .string where token.isKey:
                guard !scopeStack.isEmpty else { continue }
                let keyText = extractKeyText(from: token.span, in: utf16)
                if scopeStack[scopeStack.count - 1].contains(keyText) {
                    diagnostics.append(JSONDiagnostic(
                        severity: .error,
                        message: "Duplicate key \"\(keyText)\"",
                        span: token.span
                    ))
                } else {
                    scopeStack[scopeStack.count - 1].insert(keyText)
                }
            default:
                break
            }
        }
    }

    /// Extracts the text content of a string token (without surrounding quotes).
    private static func extractKeyText(from span: UTF16Span, in utf16: [UInt16]) -> String {
        // Skip the opening and closing quotes
        let start = span.start + 1
        let end = span.end - 1
        guard start < end, start >= 0, end <= utf16.count else { return "" }
        let slice = Array(utf16[start..<end])
        return String(utf16CodeUnits: slice, count: slice.count)
    }
}
