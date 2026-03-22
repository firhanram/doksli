import Testing
import Foundation
@testable import Doksli

// MARK: - Basic formatting

@Test func formatCompactObject() {
    let input = #"{"b":2,"a":1}"#
    let result = JSONFormatter.prettyPrint(input)
    #expect(result != nil)
    #expect(result!.contains("\n"))
}

@Test func formatPreservesKeyOrder() {
    // Unlike JSONValidator.prettyPrint which uses sortedKeys,
    // JSONFormatter preserves original key order
    let input = #"{"z":1,"a":2}"#
    let result = JSONFormatter.prettyPrint(input)!
    let zIndex = result.range(of: "\"z\"")!.lowerBound
    let aIndex = result.range(of: "\"a\"")!.lowerBound
    #expect(zIndex < aIndex)
}

@Test func formatCompactArray() {
    let input = "[1,2,3]"
    let result = JSONFormatter.prettyPrint(input)
    #expect(result != nil)
    #expect(result!.contains("\n"))
}

@Test func formatIdempotent() {
    let input = #"{"a":1,"b":2}"#
    let first = JSONFormatter.prettyPrint(input)!
    let second = JSONFormatter.prettyPrint(first)!
    #expect(first == second)
}

@Test func formatNestedObjects() {
    let input = #"{"outer":{"inner":{"deep":true}}}"#
    let result = JSONFormatter.prettyPrint(input)!
    let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
    // Should have multiple indentation levels
    let maxIndent = lines.map { $0.prefix(while: { $0 == " " }).count }.max() ?? 0
    #expect(maxIndent >= 8) // At least 2 levels of indent (4 * 2)
}

@Test func formatNestedArrays() {
    let input = "[[1,2],[3,4]]"
    let result = JSONFormatter.prettyPrint(input)!
    #expect(result.contains("\n"))
}

@Test func formatMixedObjectAndArray() {
    let input = #"{"scores":[1,2,3],"name":"Alice"}"#
    let result = JSONFormatter.prettyPrint(input)!
    #expect(result.contains("\"scores\""))
    #expect(result.contains("\"name\""))
}

// MARK: - Edge cases

@Test func formatEmptyString() {
    let result = JSONFormatter.prettyPrint("")
    #expect(result == nil)
}

@Test func formatWhitespaceOnly() {
    let result = JSONFormatter.prettyPrint("   ")
    #expect(result == nil)
}

@Test func formatInvalidJSON() {
    let result = JSONFormatter.prettyPrint("{abc}")
    #expect(result == nil)
}

@Test func formatFragmentNumber() {
    let result = JSONFormatter.prettyPrint("42")
    #expect(result == "42")
}

@Test func formatFragmentString() {
    let result = JSONFormatter.prettyPrint(#""hello""#)
    #expect(result == #""hello""#)
}

@Test func formatFragmentBoolean() {
    let result = JSONFormatter.prettyPrint("true")
    #expect(result == "true")
}

@Test func formatFragmentNull() {
    let result = JSONFormatter.prettyPrint("null")
    #expect(result == "null")
}

@Test func formatEmptyObject() {
    let result = JSONFormatter.prettyPrint("{}")
    #expect(result == "{}")
}

@Test func formatEmptyArray() {
    let result = JSONFormatter.prettyPrint("[]")
    #expect(result == "[]")
}

// MARK: - Indent options

@Test func formatCustomIndent2Spaces() {
    let input = #"{"a":1}"#
    let result = JSONFormatter.prettyPrint(input, indent: 2)!
    #expect(result.contains("  \"a\""))
    #expect(!result.contains("    \"a\""))
}

// MARK: - Value preservation

@Test func formatPreservesUnicode() {
    let input = #"{"emoji":"😀","café":"latte"}"#
    let result = JSONFormatter.prettyPrint(input)!
    #expect(result.contains("😀"))
    #expect(result.contains("café"))
}

@Test func formatPreservesAllValueTypes() {
    let input = #"{"s":"hello","n":42,"f":3.14,"b":true,"nil":null,"a":[1]}"#
    let result = JSONFormatter.prettyPrint(input)!
    #expect(result.contains("\"hello\""))
    #expect(result.contains("42"))
    #expect(result.contains("3.14"))
    #expect(result.contains("true"))
    #expect(result.contains("null"))
}

// MARK: - Structural correctness

@Test func formatColonFollowedBySpace() {
    let input = #"{"key":"value"}"#
    let result = JSONFormatter.prettyPrint(input)!
    #expect(result.contains(": "))
}

@Test func formatCommaFollowedByNewline() {
    let input = #"{"a":1,"b":2}"#
    let result = JSONFormatter.prettyPrint(input)!
    // After comma, next char should be newline
    #expect(result.contains(",\n"))
}

@Test func formatUnbalancedReturnsNil() {
    #expect(JSONFormatter.prettyPrint("{") == nil)
    #expect(JSONFormatter.prettyPrint("}") == nil)
    #expect(JSONFormatter.prettyPrint("[") == nil)
}
