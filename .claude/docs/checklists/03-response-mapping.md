# Verification checklist — HTTPURLResponse mapping to Response

## Inputs & outputs
- [ ] Maps `(HTTPURLResponse, Data, durationSeconds: Double)` → `Response`
- [ ] All 5 `Response` fields populated: `statusCode`, `headers`, `body`, `durationMs`, `sizeBytes`

## Happy path
- [ ] `HTTPURLResponse` with status 200, 3 headers, body `Data("hello".utf8)`, duration 0.142 → `Response(statusCode: 200, headers: [3 KVPairs], body: Data("hello".utf8), durationMs: 142.0, sizeBytes: 5)`
- [ ] `HTTPURLResponse` with status 404 and empty body → `Response(statusCode: 404, body: Data(), sizeBytes: 0)`
- [ ] `durationMs = durationSeconds * 1000` — 0.142 seconds → 142.0 ms

## Edge cases
- [ ] `allHeaderFields` keys and values are `Any` — only `String` keys and `String` values become `KVPair`; non-string entries are silently skipped via `compactMap`
- [ ] Response with 0 headers → `headers: []` (empty array, not nil)
- [ ] Large body (1 MB) → `sizeBytes` equals `data.count` exactly, no truncation
- [ ] `durationMs` sub-millisecond precision preserved (e.g. 0.0005 seconds → 0.5 ms)

## Failure cases
- [ ] Non-`HTTPURLResponse` from URLSession → `HTTPClientError.notHTTPResponse` thrown before mapping is called
- [ ] Does NOT set `enabled: false` on any response header `KVPair` — all are `enabled: true`

## Constraints from CLAUDE.md
- [ ] `import Foundation` only
- [ ] `sizeBytes` is set to `data.count` — NOT parsed from `Content-Length` header (which may be absent or wrong)
- [ ] All response `KVPair` have freshly generated `UUID()` ids

## Does NOT do (out of scope)
- [ ] Does not decode body JSON — raw `Data` only
- [ ] Does not filter or transform headers — all present headers are included
- [ ] Does not calculate any derived stats (e.g. kb/s)

## Integration
- [ ] `KVPair` from `Request.swift` (Phase 1) used for response headers
- [ ] `Response` struct from `Response.swift` (Phase 1) is the output type
- [ ] `durationMs` consumed by `StatsBarView` (Phase 7) to display response time
