# Verification checklist — HistoryEntry

## Inputs & outputs
- [ ] `HistoryEntry` conforms to `Codable`, `Identifiable`
- [ ] Fields: `id: UUID`, `request: Request`, `response: Response`, `timestamp: Date` — all `var`, no optionals
- [ ] `request: Request` is a value copy (struct) — mutation of the original after entry creation cannot affect the stored entry

## Happy path
- [ ] Round-trip `HistoryEntry` with `timestamp: Date(timeIntervalSince1970: 1_710_000_000)` → decoded `timestamp.timeIntervalSince1970` equals `1_710_000_000` (within floating-point precision)
- [ ] Round-trip a complete `HistoryEntry` where `request.body` is `.formData([KVPair(...)])` and `response.body` is `Data("{\"id\":42}".utf8)` → all nested fields decode correctly in one pass

## Edge cases
- [ ] `response.headers: []` and `request.params: []` → no optional fields; everything present, no missing-key errors
- [ ] Two `HistoryEntry` values with identical `request` content but different `id` and `timestamp` → each encodes/decodes as fully independent value; no shared state
- [ ] `timestamp` default encoding is `.deferredToDate` (seconds since 2001-01-01) — round-trip with default `JSONDecoder` succeeds; ISO8601 string format requires the caller to set `encoder.dateEncodingStrategy = .iso8601`

## Failure cases
- [ ] JSON missing `"response"` key → throws `DecodingError`; response is not optional
- [ ] JSON missing `"timestamp"` key → throws `DecodingError`
- [ ] Malformed nested `Request` JSON inside the entry → throws `DecodingError`; does not produce partial struct

## Constraints from CLAUDE.md
- [ ] `import Foundation` only — no `import SwiftUI`
- [ ] `Request` is a struct (value type) — "snapshot" requirement is automatically satisfied; no defensive copying needed
- [ ] File contains only `HistoryEntry`

## Does NOT do (out of scope)
- [ ] Does not enforce the 100-entry cap — that is `StorageService`'s ring-buffer logic
- [ ] Does not format `timestamp` for display — that belongs in a View helper
- [ ] Does not contain a reference to the live `Request` (no class/reference semantics)

## Integration
- [ ] Depends on `Request` (from `Request.swift`) and `Response` (from `Response.swift`) — both must compile first
- [ ] `StorageService` (Phase 2) will encode/decode `[HistoryEntry]` to `~/.doksli/v1/history.json`
- [ ] `HistoryView` (Phase 9) will read `timestamp`, `request.method`, `request.name`, `response.statusCode`
