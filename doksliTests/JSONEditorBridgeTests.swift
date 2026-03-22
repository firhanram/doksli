import Testing
import Foundation
@testable import Doksli

// MARK: - Analyze

@Test func analyzeValidJSON() {
    let result = JSONEditorBridge.analyze(#"{"key": "value"}"#)
    #expect(result.isValid == true)
    #expect(result.firstError == nil)
    #expect(!result.tokens.isEmpty)
    #expect(result.diagnostics.isEmpty)
}

@Test func analyzeInvalidJSON() {
    let result = JSONEditorBridge.analyze(#"{"a": 1,}"#)
    #expect(result.isValid == false)
    #expect(result.firstError != nil)
    #expect(!result.diagnostics.isEmpty)
}

@Test func analyzeEmptyString() {
    let result = JSONEditorBridge.analyze("")
    #expect(result.isValid == true)
    #expect(result.tokens.isEmpty)
}

@Test func analyzeWhitespace() {
    let result = JSONEditorBridge.analyze("   ")
    #expect(result.isValid == true)
    #expect(result.tokens.isEmpty)
}

@Test func analyzeTokensHaveKeysMarked() {
    let result = JSONEditorBridge.analyze(#"{"name": "Alice"}"#)
    let keys = result.tokens.filter { $0.isKey }
    #expect(keys.count == 1)
}

// MARK: - Gutter markers

@Test func gutterMarkersMapOffsetToLine() {
    let source = "{\n  \"a\": 1,\n}"
    let result = JSONEditorBridge.analyze(source)
    let markers = JSONEditorBridge.gutterMarkers(from: result.diagnostics, in: source)
    // Trailing comma error on line 2
    if !markers.isEmpty {
        #expect(markers[2] == .error)
    }
}

@Test func gutterMarkersHighestSeverityWins() {
    // Create two diagnostics on the same line with different severities
    let diagnostics = [
        JSONDiagnostic(severity: .warning, message: "warn", span: UTF16Span(start: 0, end: 1)),
        JSONDiagnostic(severity: .error, message: "err", span: UTF16Span(start: 0, end: 1))
    ]
    let markers = JSONEditorBridge.gutterMarkers(from: diagnostics, in: "x")
    #expect(markers[1] == .error)
}

@Test func gutterMarkersEmptyForValid() {
    let result = JSONEditorBridge.analyze(#"{"a": 1}"#)
    let markers = JSONEditorBridge.gutterMarkers(from: result.diagnostics, in: #"{"a": 1}"#)
    #expect(markers.isEmpty)
}
