import Foundation

// MARK: - VariableResolver

struct VariableResolver {

    /// Replaces `{{key}}` tokens in `string` using the enabled variables from `environment`.
    /// Unknown variables are left as-is. Never throws. Never mutates the input.
    static func resolve(_ string: String, environment: Environment?) -> String {
        guard let env = environment, !string.isEmpty else { return string }
        let enabled = env.variables.filter { $0.enabled }
        guard !enabled.isEmpty else { return string }

        let pattern = try! NSRegularExpression(pattern: #"\{\{(\w+)\}\}"#)
        let fullRange = NSRange(string.startIndex..., in: string)
        let matches = pattern.matches(in: string, range: fullRange)
        guard !matches.isEmpty else { return string }

        // Build result by iterating matches forward, copying unchanged segments between them
        var result = ""
        var lastEnd = string.startIndex

        for match in matches {
            guard let keyRange = Range(match.range(at: 1), in: string),
                  let fullMatchRange = Range(match.range(at: 0), in: string) else { continue }

            // Copy unchanged text before this match
            result += string[lastEnd..<fullMatchRange.lowerBound]

            let key = String(string[keyRange])
            if let envVar = enabled.first(where: { $0.key == key }) {
                result += envVar.value
            } else {
                // Unknown var: leave the {{key}} token as-is
                result += string[fullMatchRange]
            }
            lastEnd = fullMatchRange.upperBound
        }

        // Copy any remaining text after the last match
        result += string[lastEnd...]
        return result
    }

    /// Builds a tooltip string listing all `{{var}}` tokens and their resolved values.
    /// Returns `nil` if no environment is set or no tokens are found.
    static func tooltipText(for string: String, environment: Environment?) -> String? {
        guard let env = environment, !string.isEmpty else { return nil }

        let pattern = try! NSRegularExpression(pattern: #"\{\{(\w+)\}\}"#)
        let fullRange = NSRange(string.startIndex..., in: string)
        let matches = pattern.matches(in: string, range: fullRange)
        guard !matches.isEmpty else { return nil }

        let enabled = env.variables.filter { $0.enabled }
        var seen = Set<String>()
        var lines: [String] = []

        for match in matches {
            guard let keyRange = Range(match.range(at: 1), in: string) else { continue }
            let key = String(string[keyRange])
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            if let envVar = enabled.first(where: { $0.key == key }) {
                lines.append("{{\(key)}} = \(envVar.value)")
            } else {
                lines.append("{{\(key)}} = (not set)")
            }
        }

        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }
}
