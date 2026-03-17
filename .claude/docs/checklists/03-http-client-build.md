# Verification checklist — HTTPClient.buildRequest(from:environment:)

## Inputs & outputs
- [ ] Signature: `static func buildRequest(from request: Request, environment: Environment?) throws -> URLRequest`
- [ ] Input `request` is never mutated — resolver returns resolved copies
- [ ] Output is a `URLRequest` fully configured for `URLSession`

## Happy path
- [ ] `GET` request with `url: "https://api.example.com/users"`, no params → `urlRequest.url` equals `"https://api.example.com/users"`, `httpMethod` is `"GET"`
- [ ] Request with 2 enabled params `page=1` and `limit=10` and 1 disabled param `debug=true` → URL query string contains `page=1&limit=10`, does NOT contain `debug=true`
- [ ] Request with `auth: .bearer("sk_live_abc123")` → `Authorization: Bearer sk_live_abc123` is in `allHTTPHeaderFields`, NOT in original `request.headers`
- [ ] Request with `auth: .basic("user@example.com", "p@ssw0rd")` → `Authorization: Basic <base64("user@example.com:p@ssw0rd")>` in headers
- [ ] Request with `auth: .apiKey("X-API-Key", "mysecret")` → `X-API-Key: mysecret` in headers
- [ ] Request with `body: .raw("{\"name\":\"Alice\"}")` → `httpBody` equals `Data("{\"name\":\"Alice\"}".utf8)`
- [ ] Request with `body: .urlEncoded([KVPair(key:"q",value:"hello world",enabled:true)])` → body is `q=hello%20world`, `Content-Type: application/x-www-form-urlencoded` header set
- [ ] Request with `url: "{{baseUrl}}/users"`, env where `baseUrl="https://api.example.com"` → resolved URL is `"https://api.example.com/users"` before building
- [ ] All 7 HTTP methods produce correct `httpMethod` string: `"GET"`, `"POST"`, `"PUT"`, `"DELETE"`, `"PATCH"`, `"OPTIONS"`, `"HEAD"`

## Edge cases
- [ ] `body: .none` → `httpBody` is nil
- [ ] `body: .formData([KVPair])` → `Content-Type` is `multipart/form-data; boundary=<uuid>`, body contains boundary-delimited parts
- [ ] Disabled headers (enabled=false) → NOT included in `allHTTPHeaderFields`
- [ ] Auth header injected even when `request.headers` is empty
- [ ] URL with existing query string + params → both present in final URL

## Failure cases
- [ ] Invalid URL string (e.g. `""` or `"not a url"` that fails `URL(string:)`) → throws `HTTPClientError.invalidURL`
- [ ] Does NOT silently use a fallback URL when parsing fails

## Constraints from CLAUDE.md
- [ ] `import Foundation` only — no `import SwiftUI`
- [ ] Never mutates `request` — `VariableResolver.resolve` returns new strings
- [ ] No third-party dependencies

## Does NOT do (out of scope)
- [ ] Does not send the request — only builds `URLRequest`
- [ ] Does not validate response — that is `send(_:environment:)`'s job
- [ ] Does not cache or store anything

## Integration
- [ ] Called by `HTTPClient.send(_:environment:)` as first step
- [ ] Uses `VariableResolver.resolve(_:environment:)` for URL, header values, raw body
- [ ] `Request`, `KVPair`, `HTTPMethod`, `RequestBody`, `Auth` from Phase 1 must compile first
