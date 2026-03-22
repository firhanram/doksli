import Testing
import Foundation
@testable import Doksli

// MARK: - Basic tokenization

@Test func tokenizeEmptyString() {
    let tokens = JSONTokenizer.tokenize("")
    #expect(tokens.isEmpty)
}

@Test func tokenizeEmptyObject() {
    let tokens = JSONTokenizer.tokenize("{}")
    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .objectOpen)
    #expect(tokens[0].span == UTF16Span(start: 0, end: 1))
    #expect(tokens[1].kind == .objectClose)
    #expect(tokens[1].span == UTF16Span(start: 1, end: 2))
}

@Test func tokenizeEmptyArray() {
    let tokens = JSONTokenizer.tokenize("[]")
    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .arrayOpen)
    #expect(tokens[1].kind == .arrayClose)
}

@Test func tokenizeSimpleObject() {
    // {"key": "value"}
    let input = #"{"key": "value"}"#
    let tokens = JSONTokenizer.tokenize(input)
    // { "key" : (ws) "value" }
    #expect(tokens.count == 6)
    #expect(tokens[0].kind == .objectOpen)
    #expect(tokens[1].kind == .string)  // "key"
    #expect(tokens[2].kind == .colon)
    #expect(tokens[3].kind == .whitespace)
    #expect(tokens[4].kind == .string)  // "value"
    #expect(tokens[5].kind == .objectClose)
}

@Test func tokenizeSimpleObjectSpans() {
    let input = #"{"key": "value"}"#
    let tokens = JSONTokenizer.tokenize(input)
    // {"key"  spans 1..6 (5 chars: "key")
    #expect(tokens[1].span == UTF16Span(start: 1, end: 6))
    // : at position 6
    #expect(tokens[2].span == UTF16Span(start: 6, end: 7))
    // space at position 7
    #expect(tokens[3].span == UTF16Span(start: 7, end: 8))
    // "value" spans 8..15
    #expect(tokens[4].span == UTF16Span(start: 8, end: 15))
}

// MARK: - Numbers

@Test func tokenizeInteger() {
    let tokens = JSONTokenizer.tokenize("42")
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .number)
    #expect(tokens[0].span == UTF16Span(start: 0, end: 2))
}

@Test func tokenizeNegativeNumber() {
    let tokens = JSONTokenizer.tokenize("-3.14")
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .number)
    #expect(tokens[0].span == UTF16Span(start: 0, end: 5))
}

@Test func tokenizeScientificNotation() {
    let tokens = JSONTokenizer.tokenize("1e10")
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .number)
    #expect(tokens[0].span == UTF16Span(start: 0, end: 4))
}

@Test func tokenizeScientificNotationNegativeExponent() {
    let tokens = JSONTokenizer.tokenize("2.5E-3")
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .number)
    #expect(tokens[0].span == UTF16Span(start: 0, end: 6))
}

@Test func tokenizeZero() {
    let tokens = JSONTokenizer.tokenize("0")
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .number)
}

// MARK: - Booleans and null

@Test func tokenizeTrue() {
    let tokens = JSONTokenizer.tokenize("true")
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .boolean)
    #expect(tokens[0].span == UTF16Span(start: 0, end: 4))
}

@Test func tokenizeFalse() {
    let tokens = JSONTokenizer.tokenize("false")
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .boolean)
    #expect(tokens[0].span == UTF16Span(start: 0, end: 5))
}

@Test func tokenizeNull() {
    let tokens = JSONTokenizer.tokenize("null")
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .null)
    #expect(tokens[0].span == UTF16Span(start: 0, end: 4))
}

// MARK: - Strings

@Test func tokenizeStringWithEscape() {
    // "hello \"world\""
    let input = #""hello \"world\"""#
    let tokens = JSONTokenizer.tokenize(input)
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .string)
    #expect(tokens[0].span == UTF16Span(start: 0, end: input.utf16.count))
}

@Test func tokenizeStringWithUnicodeEscape() {
    let input = #""\u0041""#
    let tokens = JSONTokenizer.tokenize(input)
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .string)
}

@Test func tokenizeStringWithBackslashN() {
    let input = #""\n""#
    let tokens = JSONTokenizer.tokenize(input)
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .string)
}

@Test func tokenizeUnterminatedString() {
    let input = #""hello"#
    let tokens = JSONTokenizer.tokenize(input)
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .string)
    #expect(tokens[0].span == UTF16Span(start: 0, end: input.utf16.count))
}

// MARK: - Whitespace

@Test func tokenizeWhitespace() {
    let tokens = JSONTokenizer.tokenize("  \t\n  ")
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .whitespace)
    #expect(tokens[0].span.length == 6)
}

@Test func tokenizeWhitespaceBetweenTokens() {
    let tokens = JSONTokenizer.tokenize("[ 1 , 2 ]")
    // [ (ws) 1 (ws) , (ws) 2 (ws) ]
    #expect(tokens.count == 9)
    #expect(tokens[0].kind == .arrayOpen)
    #expect(tokens[1].kind == .whitespace)
    #expect(tokens[2].kind == .number)
    #expect(tokens[3].kind == .whitespace)
    #expect(tokens[4].kind == .comma)
    #expect(tokens[5].kind == .whitespace)
    #expect(tokens[6].kind == .number)
    #expect(tokens[7].kind == .whitespace)
    #expect(tokens[8].kind == .arrayClose)
}

// MARK: - Unknown / error recovery

@Test func tokenizeUnknownCharacters() {
    let input = "{abc}"
    let tokens = JSONTokenizer.tokenize(input)
    // { (unknown for 'a') (unknown for 'b') (unknown for 'c') }
    // Actually 'a' will be unknown since it doesn't start a keyword match
    let unknowns = tokens.filter { $0.kind == .unknown }
    #expect(!unknowns.isEmpty)
    // First and last should be braces
    #expect(tokens.first?.kind == .objectOpen)
    #expect(tokens.last?.kind == .objectClose)
}

// MARK: - markKeys

@Test func markKeysSimpleObject() {
    var tokens = JSONTokenizer.tokenize(#"{"key": "value"}"#)
    JSONTokenizer.markKeys(&tokens)
    // "key" (index 1) should be marked as key
    #expect(tokens[1].isKey == true)
    // "value" (index 4) should not
    #expect(tokens[4].isKey == false)
}

@Test func markKeysMultipleKeys() {
    var tokens = JSONTokenizer.tokenize(#"{"a": 1, "b": 2}"#)
    JSONTokenizer.markKeys(&tokens)
    let keys = tokens.filter { $0.isKey }
    #expect(keys.count == 2)
}

@Test func markKeysNested() {
    var tokens = JSONTokenizer.tokenize(#"{"outer": {"inner": true}}"#)
    JSONTokenizer.markKeys(&tokens)
    let keys = tokens.filter { $0.isKey }
    #expect(keys.count == 2)
}

@Test func markKeysArrayStringsNotKeys() {
    var tokens = JSONTokenizer.tokenize(#"["a", "b"]"#)
    JSONTokenizer.markKeys(&tokens)
    let keys = tokens.filter { $0.isKey }
    #expect(keys.count == 0)
}

// MARK: - UTF-16 offset correctness

@Test func tokenizeEmojiUTF16Offsets() {
    // Emoji 😀 is U+1F600, which is 2 UTF-16 code units (surrogate pair)
    let input = #"{"k":"😀"}"#
    let tokens = JSONTokenizer.tokenize(input)
    // { "k" : "😀" }
    // Offsets: { at 0, "k" at 1-4, : at 4, "😀" at 5-9 (quote + 2 surrogates + quote = 4), } at 9
    let stringTokens = tokens.filter { $0.kind == .string }
    #expect(stringTokens.count == 2)

    let valueToken = stringTokens[1]
    // "😀" should be 4 UTF-16 code units: " (1) + surrogate pair (2) + " (1)
    #expect(valueToken.span.length == 4)

    // Total UTF-16 length of input
    #expect(tokens.last!.span.end == input.utf16.count)
}

@Test func tokenizeMultiByteCharacter() {
    // café: é is U+00E9, which is 1 UTF-16 code unit but 2 UTF-8 bytes
    let input = #"{"k":"café"}"#
    let tokens = JSONTokenizer.tokenize(input)
    let lastToken = tokens.last!
    #expect(lastToken.span.end == input.utf16.count)
}

// MARK: - Complex document

@Test func tokenizeCompleteDocument() {
    let input = """
    {
      "name": "Alice",
      "age": 30,
      "active": true,
      "address": null,
      "scores": [1, 2, 3]
    }
    """
    var tokens = JSONTokenizer.tokenize(input)
    JSONTokenizer.markKeys(&tokens)

    let keys = tokens.filter { $0.isKey }
    #expect(keys.count == 5)

    let numbers = tokens.filter { $0.kind == .number }
    #expect(numbers.count == 4) // 30, 1, 2, 3

    let booleans = tokens.filter { $0.kind == .boolean }
    #expect(booleans.count == 1)

    let nulls = tokens.filter { $0.kind == .null }
    #expect(nulls.count == 1)

    // Verify all tokens cover the entire input
    let totalLength = tokens.reduce(0) { $0 + $1.span.length }
    #expect(totalLength == input.utf16.count)
}

@Test func tokensCoverEntireInput() {
    // For any valid-ish JSON, tokens should cover every UTF-16 code unit exactly once
    let input = #"{"a": [1, true, null, "x"], "b": -3.14}"#
    let tokens = JSONTokenizer.tokenize(input)
    let totalLength = tokens.reduce(0) { $0 + $1.span.length }
    #expect(totalLength == input.utf16.count)

    // Verify contiguous (no gaps)
    for i in 1..<tokens.count {
        #expect(tokens[i].span.start == tokens[i - 1].span.end)
    }
}

@Test func tokensStartAtZero() {
    let tokens = JSONTokenizer.tokenize(#"{"a":1}"#)
    #expect(tokens.first!.span.start == 0)
}
