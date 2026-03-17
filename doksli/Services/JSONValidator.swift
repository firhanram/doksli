import Foundation

// MARK: - JSONValidator

struct JSONValidator {

    // MARK: - Types

    struct ValidationResult: Equatable {
        let isValid: Bool
        let errorMessage: String?
        let errorPosition: Int?
    }

    // MARK: - Validate

    /// Validates a string as JSON. Empty/whitespace-only is treated as valid (no body yet).
    /// Uses `JSONSerialization` with `.fragmentsAllowed`. Never throws.
    /// Also checks for trailing commas and duplicate keys which JSONSerialization allows.
    static func validate(_ string: String) -> ValidationResult {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ValidationResult(isValid: true, errorMessage: nil, errorPosition: nil)
        }

        let data = Data(string.utf8)
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        } catch {
            let nsError = error as NSError
            let message = nsError.localizedDescription
            let position = nsError.userInfo["NSJSONSerializationErrorIndex"] as? Int
            return ValidationResult(isValid: false, errorMessage: message, errorPosition: position)
        }

        // JSONSerialization is too lenient — check for trailing commas
        if let trailingError = checkTrailingCommas(trimmed) {
            return trailingError
        }

        // Check for duplicate keys
        if let dupeError = checkDuplicateKeys(trimmed) {
            return dupeError
        }

        return ValidationResult(isValid: true, errorMessage: nil, errorPosition: nil)
    }

    /// Checks for trailing commas before `}` or `]`, ignoring content inside strings.
    private static func checkTrailingCommas(_ string: String) -> ValidationResult? {
        let chars = Array(string.unicodeScalars)
        var inString = false
        var escaped = false
        var lastNonWhitespace: Unicode.Scalar?

        for (i, c) in chars.enumerated() {
            if escaped { escaped = false; continue }
            if c == "\\" && inString { escaped = true; continue }
            if c == "\"" { inString.toggle(); lastNonWhitespace = c; continue }

            if inString { continue }

            if c == "}" || c == "]" {
                if lastNonWhitespace == "," {
                    return ValidationResult(
                        isValid: false,
                        errorMessage: "Trailing comma before '\(c)' at position \(i)",
                        errorPosition: i
                    )
                }
            }

            if !c.properties.isWhitespace {
                lastNonWhitespace = c
            }
        }
        return nil
    }

    /// Checks for duplicate keys in JSON objects, ignoring content inside strings.
    private static func checkDuplicateKeys(_ string: String) -> ValidationResult? {
        let chars = Array(string.unicodeScalars)
        var inString = false
        var escaped = false
        var stack: [KeyTracker] = []

        var stringStart = -1

        for (i, c) in chars.enumerated() {
            if escaped { escaped = false; continue }
            if c == "\\" && inString { escaped = true; continue }

            if c == "\"" {
                if inString {
                    inString = false
                    // Check if this string is a key (next non-whitespace is ':')
                    if let tracker = stack.last, tracker.isObject {
                        let extracted = String(string.unicodeScalars[
                            string.unicodeScalars.index(string.unicodeScalars.startIndex, offsetBy: stringStart + 1)
                            ..<
                            string.unicodeScalars.index(string.unicodeScalars.startIndex, offsetBy: i)
                        ])
                        // Look ahead for ':'
                        var j = i + 1
                        while j < chars.count && chars[j].properties.isWhitespace { j += 1 }
                        if j < chars.count && chars[j] == ":" {
                            if tracker.keys.contains(extracted) {
                                return ValidationResult(
                                    isValid: false,
                                    errorMessage: "Duplicate key \"\(extracted)\"",
                                    errorPosition: stringStart
                                )
                            }
                            stack[stack.count - 1].keys.insert(extracted)
                        }
                    }
                } else {
                    inString = true
                    stringStart = i
                }
                continue
            }

            if inString { continue }

            if c == "{" {
                stack.append(KeyTracker(isObject: true))
            } else if c == "[" {
                stack.append(KeyTracker(isObject: false))
            } else if c == "}" || c == "]" {
                if !stack.isEmpty { stack.removeLast() }
            }
        }
        return nil
    }

    /// Tracks keys seen in a JSON object scope.
    private struct KeyTracker {
        let isObject: Bool
        var keys: Set<String> = []
    }

    // MARK: - Pretty print

    /// Pretty-prints a JSON string. Returns the original string unchanged if invalid.
    /// Empty string returns empty string. Never throws.
    static func prettyPrint(_ string: String) -> String {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return string }

        let data = Data(string.utf8)
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) else {
            return string
        }

        // Fragments (string, number, bool, null) can't be pretty-printed via JSONSerialization.data
        // because it requires top-level array or object. Return as-is for fragments.
        guard JSONSerialization.isValidJSONObject(jsonObject) else {
            return string
        }

        guard let prettyData = try? JSONSerialization.data(
            withJSONObject: jsonObject,
            options: [.prettyPrinted, .sortedKeys]
        ),
        let prettyString = String(data: prettyData, encoding: .utf8) else {
            return string
        }

        return prettyString
    }

    // MARK: - Indent level

    /// Calculates the JSON indent depth at a given character position by counting
    /// unmatched `{` and `[` before that position, ignoring those inside string literals.
    /// Returns the number of spaces (depth * 4).
    static func indentLevel(at position: Int, in string: String) -> Int {
        guard position > 0, !string.isEmpty else { return 0 }

        let chars = Array(string.unicodeScalars)
        let end = min(position, chars.count)
        var depth = 0
        var inString = false
        var escaped = false

        for i in 0..<end {
            let c = chars[i]

            if escaped {
                escaped = false
                continue
            }

            if c == "\\" && inString {
                escaped = true
                continue
            }

            if c == "\"" {
                inString.toggle()
                continue
            }

            if !inString {
                if c == "{" || c == "[" {
                    depth += 1
                } else if c == "}" || c == "]" {
                    depth -= 1
                }
            }
        }

        return max(0, depth) * 4
    }
}
