import Testing
import Foundation
@testable import Doksli

// MARK: - Helper

private func lint(_ input: String) -> [JSONDiagnostic] {
    var tokens = JSONTokenizer.tokenize(input)
    JSONTokenizer.markKeys(&tokens)
    return JSONLinter.lint(tokens: tokens, source: input)
}

private func errors(_ input: String) -> [JSONDiagnostic] {
    lint(input).filter { $0.severity == .error }
}

// MARK: - Valid JSON

@Test func validEmptyObject() {
    #expect(errors("{}").isEmpty)
}

@Test func validEmptyArray() {
    #expect(errors("[]").isEmpty)
}

@Test func validSimpleObject() {
    #expect(errors(#"{"key": "value"}"#).isEmpty)
}

@Test func validNestedObject() {
    #expect(errors(#"{"a":{"b":{"c":1}}}"#).isEmpty)
}

@Test func validArray() {
    #expect(errors("[1, 2, 3]").isEmpty)
}

@Test func validMixed() {
    #expect(errors(#"{"a": [1, true, null, "x"], "b": -3.14}"#).isEmpty)
}

@Test func validEmptyString() {
    #expect(lint("").isEmpty)
}

@Test func validWhitespaceOnly() {
    #expect(lint("   \n  ").isEmpty)
}

@Test func validBooleans() {
    #expect(errors("true").isEmpty)
    #expect(errors("false").isEmpty)
}

@Test func validNull() {
    #expect(errors("null").isEmpty)
}

@Test func validNumber() {
    #expect(errors("42").isEmpty)
}

// MARK: - Trailing commas

@Test func trailingCommaObject() {
    let diags = errors(#"{"a": 1,}"#)
    #expect(diags.count >= 1)
    #expect(diags.first?.message.contains("Trailing comma") == true)
}

@Test func trailingCommaArray() {
    let diags = errors("[1, 2,]")
    #expect(diags.count >= 1)
    #expect(diags.first?.message.contains("Trailing comma") == true)
}

@Test func trailingCommaSpanIsComma() {
    let input = #"{"a": 1,}"#
    let diags = errors(input)
    let trailingDiag = diags.first { $0.message.contains("Trailing comma") }!
    // The comma is at position 7
    #expect(trailingDiag.span.length == 1)
}

// MARK: - Duplicate keys

@Test func duplicateKeysSimple() {
    let diags = errors(#"{"a": 1, "a": 2}"#)
    #expect(diags.count >= 1)
    #expect(diags.first?.message.contains("Duplicate") == true)
}

@Test func duplicateKeysNested() {
    let diags = errors(#"{"x": {"a": 1, "a": 2}}"#)
    #expect(diags.count >= 1)
    #expect(diags.first?.message.contains("Duplicate") == true)
}

@Test func sameKeyDifferentObjects() {
    #expect(errors(#"{"obj1": {"a": 1}, "obj2": {"a": 2}}"#).isEmpty)
}

@Test func duplicateKeyMessageContainsKeyName() {
    let diags = errors(#"{"name": 1, "name": 2}"#)
    let dupDiag = diags.first { $0.message.contains("Duplicate") }
    #expect(dupDiag?.message.contains("name") == true)
}

// MARK: - Structural errors

@Test func unclosedBrace() {
    let diags = errors(#"{"key": "value""#)
    #expect(diags.count >= 1)
    let hasUnclosed = diags.contains { $0.message.contains("Unclosed") }
    #expect(hasUnclosed)
}

@Test func unclosedBracket() {
    let diags = errors("[1, 2, 3")
    #expect(diags.count >= 1)
    let hasUnclosed = diags.contains { $0.message.contains("Unclosed") }
    #expect(hasUnclosed)
}

@Test func extraCloseBrace() {
    let diags = errors("}")
    #expect(diags.count >= 1)
    let hasUnexpected = diags.contains { $0.message.contains("Unexpected") }
    #expect(hasUnexpected)
}

@Test func extraCloseBracket() {
    let diags = errors("]")
    #expect(diags.count >= 1)
}

@Test func mismatchedBraceAndBracket() {
    let diags = errors("{]")
    #expect(diags.count >= 1)
}

// MARK: - Unknown tokens

@Test func unknownCharacterProducesError() {
    let diags = errors("{@}")
    let hasUnexpected = diags.contains { $0.message.contains("Unexpected character") }
    #expect(hasUnexpected)
}

// MARK: - Multiple errors

@Test func multipleErrorsInOneDocument() {
    // Trailing comma AND duplicate key
    let diags = errors(#"{"a": 1, "a": 2,}"#)
    let hasDup = diags.contains { $0.message.contains("Duplicate") }
    let hasTrailing = diags.contains { $0.message.contains("Trailing comma") }
    #expect(hasDup)
    #expect(hasTrailing)
}
