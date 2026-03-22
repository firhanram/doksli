import Testing
import AppKit
@testable import Doksli

// MARK: - Color mapping tests

@Test func colorForStringKey() {
    let color = SyntaxHighlighter.color(for: .string, isKey: true)
    #expect(color == AppColors.NS.jsonKey)
}

@Test func colorForStringValue() {
    let color = SyntaxHighlighter.color(for: .string, isKey: false)
    #expect(color == AppColors.NS.jsonString)
}

@Test func colorForNumber() {
    let color = SyntaxHighlighter.color(for: .number, isKey: false)
    #expect(color == AppColors.NS.jsonNumber)
}

@Test func colorForBoolean() {
    let color = SyntaxHighlighter.color(for: .boolean, isKey: false)
    #expect(color == AppColors.NS.jsonBoolean)
}

@Test func colorForNull() {
    let color = SyntaxHighlighter.color(for: .null, isKey: false)
    #expect(color == AppColors.NS.jsonNull)
}

@Test func colorForPunctuation() {
    for kind: JSONTokenKind in [.objectOpen, .objectClose, .arrayOpen, .arrayClose, .colon, .comma] {
        let color = SyntaxHighlighter.color(for: kind, isKey: false)
        #expect(color == AppColors.NS.jsonPunctuation)
    }
}

@Test func colorForUnknown() {
    let color = SyntaxHighlighter.color(for: .unknown, isKey: false)
    #expect(color == AppColors.NS.errorText)
}

@Test func colorForWhitespace() {
    let color = SyntaxHighlighter.color(for: .whitespace, isKey: false)
    #expect(color == AppColors.NS.textPrimary)
}

@Test func fontIsMonospaced() {
    let font = SyntaxHighlighter.font
    #expect(font.pointSize == 12)
}
