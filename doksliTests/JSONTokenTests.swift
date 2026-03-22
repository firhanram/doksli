import Testing
import Foundation
@testable import Doksli

// MARK: - UTF16Span tests

@Test func spanLengthCalculation() {
    let span = UTF16Span(start: 3, end: 7)
    #expect(span.length == 4)
}

@Test func spanLengthZero() {
    let span = UTF16Span(start: 5, end: 5)
    #expect(span.length == 0)
}

@Test func spanNSRangeConversion() {
    let span = UTF16Span(start: 10, end: 15)
    let nsRange = span.nsRange
    #expect(nsRange.location == 10)
    #expect(nsRange.length == 5)
}

@Test func spanEquality() {
    let a = UTF16Span(start: 0, end: 3)
    let b = UTF16Span(start: 0, end: 3)
    let c = UTF16Span(start: 0, end: 4)
    #expect(a == b)
    #expect(a != c)
}

@Test func spanHashable() {
    let a = UTF16Span(start: 0, end: 3)
    let b = UTF16Span(start: 0, end: 3)
    var set = Set<UTF16Span>()
    set.insert(a)
    set.insert(b)
    #expect(set.count == 1)
}

// MARK: - JSONToken tests

@Test func tokenEquality() {
    let a = JSONToken(kind: .string, span: UTF16Span(start: 0, end: 5))
    let b = JSONToken(kind: .string, span: UTF16Span(start: 0, end: 5))
    #expect(a == b)
}

@Test func tokenInequalityKind() {
    let a = JSONToken(kind: .string, span: UTF16Span(start: 0, end: 5))
    let b = JSONToken(kind: .number, span: UTF16Span(start: 0, end: 5))
    #expect(a != b)
}

@Test func tokenInequalitySpan() {
    let a = JSONToken(kind: .string, span: UTF16Span(start: 0, end: 5))
    let b = JSONToken(kind: .string, span: UTF16Span(start: 0, end: 6))
    #expect(a != b)
}

@Test func tokenIsKeyDefaultsFalse() {
    let token = JSONToken(kind: .string, span: UTF16Span(start: 0, end: 5))
    #expect(token.isKey == false)
}

@Test func tokenIsKeyCanBeSet() {
    var token = JSONToken(kind: .string, span: UTF16Span(start: 0, end: 5))
    token.isKey = true
    #expect(token.isKey == true)
}

@Test func tokenIsKeyAffectsEquality() {
    let a = JSONToken(kind: .string, span: UTF16Span(start: 0, end: 5), isKey: false)
    let b = JSONToken(kind: .string, span: UTF16Span(start: 0, end: 5), isKey: true)
    #expect(a != b)
}
