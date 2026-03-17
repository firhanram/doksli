import Testing
import Foundation
@testable import doksli

// MARK: - Validation tests

@Test func validateValidObject() {
    let result = JSONValidator.validate(#"{"name":"Alice","age":30}"#)
    #expect(result.isValid == true)
    #expect(result.errorMessage == nil)
    #expect(result.errorPosition == nil)
}

@Test func validateValidArray() {
    let result = JSONValidator.validate("[1, 2, 3]")
    #expect(result.isValid == true)
    #expect(result.errorMessage == nil)
}

@Test func validateValidFragmentString() {
    let result = JSONValidator.validate(#""hello""#)
    #expect(result.isValid == true)
}

@Test func validateValidFragmentNumber() {
    let result = JSONValidator.validate("42")
    #expect(result.isValid == true)
}

@Test func validateValidFragmentBoolean() {
    let result = JSONValidator.validate("true")
    #expect(result.isValid == true)
}

@Test func validateValidFragmentNull() {
    let result = JSONValidator.validate("null")
    #expect(result.isValid == true)
}

@Test func validateEmptyString() {
    let result = JSONValidator.validate("")
    #expect(result.isValid == true)
    #expect(result.errorMessage == nil)
}

@Test func validateWhitespaceOnly() {
    let result = JSONValidator.validate("   \n  ")
    #expect(result.isValid == true)
}

@Test func validateInvalidMissingValue() {
    let result = JSONValidator.validate(#"{"key":}"#)
    #expect(result.isValid == false)
    #expect(result.errorMessage != nil)
}

@Test func validateInvalidUnclosedBrace() {
    let result = JSONValidator.validate(#"{"key": "value""#)
    #expect(result.isValid == false)
    #expect(result.errorMessage != nil)
}

@Test func validateInvalidTrailingComma() {
    let result = JSONValidator.validate(#"{"a": 1,}"#)
    #expect(result.isValid == false)
    #expect(result.errorMessage != nil)
}

@Test func validateInvalidTrailingCommaArray() {
    let result = JSONValidator.validate("[1, 2,]")
    #expect(result.isValid == false)
    #expect(result.errorMessage != nil)
}

@Test func validateInvalidDuplicateKeys() {
    let result = JSONValidator.validate(#"{"a": 1, "a": 2}"#)
    #expect(result.isValid == false)
    #expect(result.errorMessage?.contains("Duplicate") == true)
}

@Test func validateInvalidDuplicateKeysNested() {
    // Duplicate keys in inner object, outer keys are unique
    let result = JSONValidator.validate(#"{"x": {"a": 1, "a": 2}}"#)
    #expect(result.isValid == false)
    #expect(result.errorMessage?.contains("Duplicate") == true)
}

@Test func validateNoDuplicateAcrossObjects() {
    // Same key in different objects is fine
    let result = JSONValidator.validate(#"{"obj1": {"a": 1}, "obj2": {"a": 2}}"#)
    #expect(result.isValid == true)
}

@Test func validateInvalidBareWord() {
    let result = JSONValidator.validate("hello")
    #expect(result.isValid == false)
    #expect(result.errorMessage != nil)
}

@Test func validateDeeplyNested() {
    let result = JSONValidator.validate(#"{"a":{"b":{"c":{"d":1}}}}"#)
    #expect(result.isValid == true)
}

// MARK: - Pretty print tests

@Test func prettyPrintCompactObject() {
    let input = #"{"b":2,"a":1}"#
    let result = JSONValidator.prettyPrint(input)
    #expect(result.contains("\n"))
    // Sorted keys: "a" before "b"
    let aIndex = result.range(of: "\"a\"")!.lowerBound
    let bIndex = result.range(of: "\"b\"")!.lowerBound
    #expect(aIndex < bIndex)
}

@Test func prettyPrintCompactArray() {
    let input = "[1,2,3]"
    let result = JSONValidator.prettyPrint(input)
    #expect(result.contains("\n"))
}

@Test func prettyPrintInvalidReturnsOriginal() {
    let input = "not json"
    let result = JSONValidator.prettyPrint(input)
    #expect(result == "not json")
}

@Test func prettyPrintEmptyReturnsEmpty() {
    let result = JSONValidator.prettyPrint("")
    #expect(result == "")
}

@Test func prettyPrintIdempotent() {
    let input = #"{"a":1,"b":2}"#
    let first = JSONValidator.prettyPrint(input)
    let second = JSONValidator.prettyPrint(first)
    #expect(first == second)
}

@Test func prettyPrintPreservesAllValues() {
    let input = #"{"string":"hello","number":42,"bool":true,"null":null,"array":[1,2]}"#
    let result = JSONValidator.prettyPrint(input)
    // Parse back and verify values preserved
    let data = Data(result.utf8)
    let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(parsed["string"] as? String == "hello")
    #expect(parsed["number"] as? Int == 42)
    #expect(parsed["bool"] as? Bool == true)
    #expect(parsed["null"] is NSNull)
    #expect((parsed["array"] as? [Int]) == [1, 2])
}

@Test func prettyPrintFragmentReturnsOriginal() {
    // Fragments (string, number, bool, null) can't be pretty-printed
    let result = JSONValidator.prettyPrint("42")
    #expect(result == "42")
}

// MARK: - Indent level tests

@Test func indentLevelAtStart() {
    let result = JSONValidator.indentLevel(at: 0, in: #"{"key":"value"}"#)
    #expect(result == 0)
}

@Test func indentLevelAfterOpenBrace() {
    // Position after '{'
    let result = JSONValidator.indentLevel(at: 1, in: #"{"key":"value"}"#)
    #expect(result == 4)
}

@Test func indentLevelNested() {
    let input = #"{"a":{"b":1}}"#
    // Position after second '{' (index 5: {"a":{ )
    let result = JSONValidator.indentLevel(at: 6, in: input)
    #expect(result == 8)
}

@Test func indentLevelAfterCloseBrace() {
    let input = #"{"a":{"b":1}}"#
    // Position after inner '}' (index 12: {"a":{"b":1})
    let result = JSONValidator.indentLevel(at: 12, in: input)
    #expect(result == 4)
}

@Test func indentLevelBraceInsideString() {
    let input = #"{"key":"value with { brace"}"#
    // The { inside the string value should not be counted
    // After the outer '{' at position 0, depth is 1
    let result = JSONValidator.indentLevel(at: 27, in: input)
    #expect(result == 4) // Only outer brace counts
}

@Test func indentLevelNegativeDepthClamped() {
    let result = JSONValidator.indentLevel(at: 2, in: "}}")
    #expect(result == 0)
}

@Test func indentLevelBeyondStringLength() {
    let result = JSONValidator.indentLevel(at: 100, in: "short")
    #expect(result == 0)
}

@Test func indentLevelEmptyString() {
    let result = JSONValidator.indentLevel(at: 0, in: "")
    #expect(result == 0)
}

@Test func indentLevelWithArray() {
    let input = "[1,2]"
    let result = JSONValidator.indentLevel(at: 1, in: input)
    #expect(result == 4)
}

@Test func indentLevelEscapedQuote() {
    // String with escaped quote: {"key":"val\"ue"}
    let input = #"{"key":"val\"ue"}"#
    // The escaped quote should not toggle inString state
    let result = JSONValidator.indentLevel(at: input.count, in: input)
    #expect(result == 0) // All braces closed
}
