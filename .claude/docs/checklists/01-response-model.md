# Verification checklist — Response model

## Inputs & outputs
- [ ] `Response` conforms to `Codable` (required — `HistoryEntry` embeds it and `StorageService` persists history)
- [ ] All 5 fields present: `statusCode: Int`, `headers: [KVPair]`, `body: Data`, `durationMs: Double`, `sizeBytes: Int`
- [ ] `body: Data` — `JSONEncoder` default encodes `Data` as base64; no custom encoding needed
- [ ] No optional fields — all 5 fields are required in JSON

## Happy path
- [ ] Round-trip `Response(statusCode: 200, headers: [KVPair(id: UUID(), key: "Content-Type", value: "application/json", enabled: true)], body: Data("Hello, World!".utf8), durationMs: 142.7, sizeBytes: 13)` → decoded struct has identical values; body decodes from base64 back to the same UTF-8 bytes
- [ ] Round-trip `Response(statusCode: 404, headers: [], body: Data(), durationMs: 38.0, sizeBytes: 0)` → decoded correctly; empty `Data` round-trips without error

## Edge cases
- [ ] `body` containing arbitrary binary bytes `Data([0x00, 0xFF, 0xFE, 0x80])` → encodes as base64 string in JSON, decodes back to identical byte sequence
- [ ] `durationMs: 0.001` (sub-millisecond) → `Double` precision preserved through encode/decode
- [ ] `headers` with 50+ `KVPair` values → no truncation or error

## Failure cases
- [ ] JSON with `"body"` as a non-base64 string → `JSONDecoder` throws `DecodingError`
- [ ] JSON with `"statusCode": "200"` (string instead of Int) → throws `DecodingError`
- [ ] JSON missing `"durationMs"` key → throws `DecodingError`; no field has a default value

## Constraints from CLAUDE.md
- [ ] `import Foundation` only — no `import SwiftUI`
- [ ] File contains only `Response` struct
- [ ] `Response` must be `Codable` — this is a hard requirement for history persistence

## Does NOT do (out of scope)
- [ ] Does not decode `body` as JSON or text — that is `JSONTreeView`'s and `RawBodyView`'s responsibility
- [ ] Does not contain status-code-to-color mapping — that belongs in a View helper
- [ ] Does not calculate `sizeBytes` — caller (`HTTPClient`) sets it to `data.count`

## Integration
- [ ] `HistoryEntry.response: Response` embeds this type
- [ ] `AppState.pendingResponse: Response?` holds the live result
- [ ] `KVPair` from `Request.swift` must compile before this file
