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
        checkGrammar(tokens, into: &diagnostics)
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

    // MARK: - Grammar (object members must be key:value pairs)

    private static func checkGrammar(_ tokens: [JSONToken],
                                     into diagnostics: inout [JSONDiagnostic]) {
        let sig = tokens.filter { $0.kind != .whitespace }
        let isValue: (JSONTokenKind) -> Bool = { kind in
            switch kind {
            case .string, .number, .boolean, .null, .objectOpen, .arrayOpen:
                return true
            default:
                return false
            }
        }

        var contextStack: [Bool] = [] // true = object, false = array
        var expectingKey = false

        for i in 0..<sig.count {
            let token = sig[i]
            switch token.kind {
            case .objectOpen:
                contextStack.append(true)
                expectingKey = true

            case .arrayOpen:
                contextStack.append(false)
                expectingKey = false

            case .objectClose:
                if !contextStack.isEmpty { contextStack.removeLast() }
                expectingKey = false

            case .arrayClose:
                if !contextStack.isEmpty { contextStack.removeLast() }
                expectingKey = false

            case .comma:
                if contextStack.last == true {
                    expectingKey = true
                }

            case .colon:
                // After colon, the next significant token must be a value.
                let next = i + 1 < sig.count ? sig[i + 1] : nil
                if let next = next {
                    if !isValue(next.kind) {
                        diagnostics.append(JSONDiagnostic(
                            severity: .error,
                            message: "Expected value after ':'",
                            span: token.span
                        ))
                    }
                } else {
                    diagnostics.append(JSONDiagnostic(
                        severity: .error,
                        message: "Expected value after ':'",
                        span: token.span
                    ))
                }
                expectingKey = false

            case .string, .number, .boolean, .null:
                let inObject = contextStack.last == true
                if inObject && expectingKey {
                    if token.kind != .string || !token.isKey {
                        diagnostics.append(JSONDiagnostic(
                            severity: .error,
                            message: "Expected a key (string) but found value",
                            span: token.span
                        ))
                    }
                    expectingKey = false
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
