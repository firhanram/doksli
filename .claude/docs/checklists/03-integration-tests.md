# Verification checklist — Integration tests against httpbin.org

## Inputs & outputs
- [ ] Tests use `HTTPClient.send(_:environment:)` end-to-end (not `buildRequest` alone)
- [ ] Tests use Swift Testing (`import Testing`, `@Test`, `#expect`) — consistent with existing test suite
- [ ] Network-dependent tests annotated with `@Test(.timeLimit(.minutes(1)))` to avoid CI hangs

## Happy path
- [ ] `GET https://httpbin.org/get` → `response.statusCode == 200`, `response.body` is non-empty JSON
- [ ] `POST https://httpbin.org/post` with `body: .raw("{\"name\":\"Alice\"}")` and `Content-Type: application/json` header → status 200, response body JSON echoes the sent data
- [ ] `DELETE https://httpbin.org/delete` → `response.statusCode == 200`
- [ ] Custom header `X-Test-Header: round-trip-value` sent → appears in response body JSON under `"headers"` key

## Edge cases
- [ ] `response.durationMs > 0` for all successful requests — timing is actually measured
- [ ] `response.sizeBytes == response.body.count` — consistent for all responses

## Failure cases
- [ ] These are integration tests — they require live network access. If httpbin.org is unreachable the test throws `URLError`; this is expected and acceptable

## Constraints from CLAUDE.md
- [ ] Tests use `URLSession.shared` via `HTTPClient.send` — no mocking
- [ ] No hardcoded timeouts shorter than 30 seconds — httpbin.org can be slow
- [ ] Tests in `doksliTests` target (not `doksliUITests`)

## Does NOT do (out of scope)
- [ ] Does not test SSL certificate pinning
- [ ] Does not test authentication flows end-to-end (only via `buildRequest` unit tests)
- [ ] Does not test httpbin.org's specific JSON schema — only status codes and non-empty body

## Integration
- [ ] Exercises `VariableResolver` → `HTTPClient.buildRequest` → `URLSession` → response mapping full chain
- [ ] `doksli/doksli.entitlements` must have `com.apple.security.network.client = true` — already set in Phase 0
