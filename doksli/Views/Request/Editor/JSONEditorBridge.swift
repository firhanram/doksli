import Foundation

// MARK: - JSONEditorBridge

struct JSONEditorBridge {

    /// Result of the full analysis pipeline.
    struct AnalysisResult {
        let tokens: [JSONToken]
        let diagnostics: [JSONDiagnostic]
        let isValid: Bool
        let firstError: String?

        static let empty = AnalysisResult(
            tokens: [], diagnostics: [], isValid: true, firstError: nil
        )
    }

    /// Runs the full pipeline: tokenize → markKeys → lint.
    static func analyze(_ string: String) -> AnalysisResult {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }

        var tokens = JSONTokenizer.tokenize(string)
        JSONTokenizer.markKeys(&tokens)
        let diagnostics = JSONLinter.lint(tokens: tokens, source: string)
        let errors = diagnostics.filter { $0.severity == .error }

        return AnalysisResult(
            tokens: tokens,
            diagnostics: diagnostics,
            isValid: errors.isEmpty,
            firstError: errors.first?.message
        )
    }

    /// Converts diagnostics to line-keyed dictionary for the gutter.
    /// Keeps highest severity per line (error > warning > hint).
    /// Uses the gutter's visual line numbering when available.
    static func gutterMarkers(from diagnostics: [JSONDiagnostic],
                              in string: String,
                              gutter: GutterView? = nil) -> [Int: DiagnosticSeverity] {
        var result: [Int: DiagnosticSeverity] = [:]
        for diag in diagnostics {
            let line: Int
            if let gutter = gutter {
                line = gutter.visualLineNumber(forUTF16Offset: diag.span.start)
            } else {
                line = GutterView.lineNumber(forUTF16Offset: diag.span.start, in: string)
            }
            if let existing = result[line] {
                if priority(diag.severity) > priority(existing) {
                    result[line] = diag.severity
                }
            } else {
                result[line] = diag.severity
            }
        }
        return result
    }

    private static func priority(_ severity: DiagnosticSeverity) -> Int {
        switch severity {
        case .error: return 3
        case .warning: return 2
        case .hint: return 1
        }
    }
}
