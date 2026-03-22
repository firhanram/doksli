import Foundation

// MARK: - UTF16Span

/// A half-open range of UTF-16 code unit offsets within a source string.
/// Directly compatible with NSRange: `NSRange(location: start, length: length)`.
struct UTF16Span: Equatable, Hashable {
    let start: Int   // inclusive
    let end: Int     // exclusive

    var length: Int { end - start }
    var nsRange: NSRange { NSRange(location: start, length: length) }
}

// MARK: - JSONTokenKind

enum JSONTokenKind: Equatable {
    case objectOpen        // {
    case objectClose       // }
    case arrayOpen         // [
    case arrayClose        // ]
    case colon             // :
    case comma             // ,
    case string            // "..." (both keys and string values)
    case number            // integer or decimal
    case boolean           // true / false
    case null              // null
    case whitespace        // spaces, tabs, newlines between tokens
    case unknown           // unrecognized character(s) — error recovery
}

// MARK: - JSONToken

/// A single token in a JSON document. All offsets are UTF-16 code units.
struct JSONToken: Equatable {
    let kind: JSONTokenKind
    let span: UTF16Span

    /// Whether this string token is an object key (followed by colon).
    /// Set by `JSONTokenizer.markKeys` after tokenization.
    var isKey: Bool = false
}
