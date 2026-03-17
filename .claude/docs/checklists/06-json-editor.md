# Verification checklist — JSON editor (raw body mode)

## Inputs & outputs — JSONValidator
- [ ] Input type: `String` — matches the raw body text
- [ ] Output type: `ValidationResult` struct with `isValid: Bool`, `errorMessage: String?`, `errorPosition: Int?`
- [ ] `prettyPrint` signature: `static func prettyPrint(_ string: String) -> String`
- [ ] `validate` signature: `static func validate(_ string: String) -> ValidationResult`
- [ ] `indentLevel` signature: `static func indentLevel(at position: Int, in string: String) -> Int`

## Happy path — validation
- [ ] `validate('{"name":"Alice","age":30}')` → isValid: true, errorMessage: nil
- [ ] `validate('[1, 2, 3]')` → isValid: true, errorMessage: nil
- [ ] `validate('"hello"')` → isValid: true (fragment allowed)
- [ ] `validate('42')` → isValid: true (fragment allowed)

## Happy path — pretty print
- [ ] `prettyPrint('{"a":1,"b":2}')` → multiline with indentation, keys sorted
- [ ] `prettyPrint('[1,2,3]')` → multiline array with each element on its own line

## Happy path — indent level
- [ ] After `{` (position 1) → indent level 4 (1 level × 4 spaces)
- [ ] After `{"a":{` (nested) → indent level 8 (2 levels × 4 spaces)
- [ ] At start of string (position 0) → indent level 0

## Happy path — syntax highlighting
- [ ] Keys colored orange (`nsJsonKey` #C96A2A)
- [ ] String values colored green (`nsJsonString` #2D7F4E)
- [ ] Numbers colored purple (`nsJsonNumber` #6040A0)
- [ ] Booleans colored blue (`nsJsonBoolean` #1E5F8F)
- [ ] Null colored gray (`nsJsonNull` #8C8982)
- [ ] Punctuation `{}[]:,` colored tertiary (`nsJsonPunctuation` #6B6760)

## Happy path — editor engine
- [ ] Line numbers visible in gutter
- [ ] Undo/redo works (Cmd+Z / Cmd+Shift+Z)
- [ ] Find bar works (Cmd+F)
- [ ] Cut/copy/paste works
- [ ] Text selection works (click/drag/shift+arrow)

## Edge cases — validation
- [ ] Empty string `""` → isValid: true (no body yet, not an error)
- [ ] Whitespace-only `"   "` → isValid: true (treated same as empty)
- [ ] `validate('{"key":}')` → isValid: false, errorMessage is non-nil
- [ ] `validate('{')` → isValid: false, errorMessage describes unexpected EOF

## Edge cases — pretty print
- [ ] Invalid JSON `prettyPrint('not json')` → returns `"not json"` unchanged
- [ ] Empty string `prettyPrint('')` → returns `""` unchanged
- [ ] Already-formatted JSON → returns equivalent output (idempotent)
- [ ] Fragment (number, string, bool) → returns original unchanged

## Edge cases — indent level
- [ ] String with `{` inside a JSON string literal → brace inside quotes not counted
- [ ] Negative depth (more `}` than `{`) → clamped to 0, no crash
- [ ] Position beyond string length → returns 0, no crash
- [ ] Escaped quote inside string → does not toggle string state

## Edge cases — syntax highlighting
- [ ] Escaped quotes in strings → no breakage, string boundary correct
- [ ] Invalid/partial JSON → partial highlighting, no crash
- [ ] Empty string → no crash
- [ ] Nested objects → inner keys colored as keys, inner values as values
- [ ] Arrays → elements colored as values, not keys

## Failure cases
- [ ] `validate` never throws — always returns a `ValidationResult`
- [ ] `prettyPrint` never throws — returns original string on failure
- [ ] `indentLevel` never crashes on any input
- [ ] Syntax highlighter never crashes on any input

## Constraints from CLAUDE.md
- [ ] No third-party imports — Foundation + AppKit + SwiftUI only
- [ ] No hardcoded hex colors — AppColors / AppColors.ns* tokens only
- [ ] No hardcoded spacing — AppSpacing constants only
- [ ] No business logic in Views — validation in JSONValidator, highlighting in JSONSyntaxHighlighter
- [ ] CodeEditorView is generic — no JSON knowledge in the editor engine

## UI requirements
- [ ] Validation indicator visible above editor (green check or red exclamation)
- [ ] Format button visible in toolbar row, disabled when JSON invalid
- [ ] Error message banner shown below editor only when invalid
- [ ] Error banner uses AppColors.errorBg background + AppColors.errorText text
- [ ] Success indicator uses AppColors.successText color
- [ ] Validation debounced (300ms) — no lag on large payloads
- [ ] Syntax highlighting debounced (150ms)
- [ ] Auto-indent inserts correct spaces after Enter key (integrated with undo)
- [ ] Empty editor shows no validation indicator
- [ ] Line numbers in gutter, right-aligned, SF Mono 10pt

## Does NOT do (out of scope)
- [ ] Does not modify RequestBody enum or any model
- [ ] Does not change HTTPClient behavior
- [ ] Does not force Content-Type header — user manages headers manually
- [ ] Does not add bracket matching highlight (future enhancement)

## Integration
- [ ] RawJSONEditor receives the same `rawTextBinding` from BodyEditor
- [ ] Typing in editor still updates `RequestBody.raw(String)` via binding
- [ ] Format button updates the binding, which propagates to the model
- [ ] Existing body modes (none, formData, urlEncoded) are unaffected
- [ ] Send request with formatted JSON body works correctly
- [ ] Auto-indent undoes cleanly with Cmd+Z (single undo step)
