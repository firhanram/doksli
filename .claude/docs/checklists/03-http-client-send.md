# Verification checklist — HTTPClient.send(_:environment:)

## Inputs & outputs
- [ ] Signature: `static func send(_ request: Request, environment: Environment?) async throws -> Response`
- [ ] Returns `Response` on success
- [ ] Throws on network error or non-HTTP response — does NOT return a partial/empty Response

## Happy path
- [ ] Successful send returns a `Response` with `statusCode`, `headers`, `body`, `durationMs`, `sizeBytes` all populated
- [ ] `durationMs` is greater than 0 — timing actually measured (not hardcoded to 0)
- [ ] `sizeBytes` equals `response.body.count`

## Edge cases
- [ ] Cancellation: if the task is cancelled, `URLSession` propagates `CancellationError` — does NOT hang or return partial data
- [ ] Network error (e.g. offline): `URLError` propagates from `URLSession.data(for:)` — caller receives the error
- [ ] Non-HTTP response (theoretical): throws `HTTPClientError.notHTTPResponse`

## Failure cases
- [ ] Invalid URL in request → `buildRequest` throws `HTTPClientError.invalidURL`, propagated by `send`
- [ ] Network error → throws `URLError`, does NOT return a Response with statusCode 0
- [ ] Does NOT silently swallow errors with `try?`

## Constraints from CLAUDE.md
- [ ] `import Foundation` only — no `import SwiftUI`
- [ ] Uses `ContinuousClock` for timing — NOT `Date()` subtraction
- [ ] Uses `URLSession.shared` — no custom session configuration needed at this phase
- [ ] `async throws` — conforms to Swift concurrency model

## Does NOT do (out of scope)
- [ ] Does not retry on failure — single attempt only
- [ ] Does not cache responses
- [ ] Does not validate SSL certificates beyond URLSession defaults
- [ ] Does not follow redirects beyond URLSession defaults

## Integration
- [ ] Calls `buildRequest(from:environment:)` as first step
- [ ] Returns `Response` consumed by `AppState.pendingResponse` (Phase 4)
- [ ] `ContinuousClock` available from macOS 13.0 — matches deployment target
