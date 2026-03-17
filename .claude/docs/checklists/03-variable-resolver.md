# Verification checklist — VariableResolver.resolve(_:environment:)

## Inputs & outputs
- [ ] Signature: `static func resolve(_ string: String, environment: Environment?) -> String`
- [ ] Returns `String` in ALL cases — never throws, never returns nil
- [ ] Input `string` is not mutated — returns a new `String` (value type, automatic)

## Happy path
- [ ] `resolve("Bearer {{token}}", env where token="sk_live_abc")` → `"Bearer sk_live_abc"`
- [ ] `resolve("https://{{base_url}}/v1/users", env where base_url="api.example.com")` → `"https://api.example.com/v1/users"`
- [ ] Multiple vars in one string: `resolve("{{scheme}}://{{host}}", env where scheme="https", host="api.example.com")` → `"https://api.example.com"` — all replaced in one pass

## Edge cases
- [ ] Unknown var: `resolve("Bearer {{unknown}}", env)` → `"Bearer {{unknown}}"` — left as-is
- [ ] Disabled var: `resolve("{{token}}", env where token exists but enabled=false)` → `"{{token}}"` — not substituted
- [ ] Nil environment: `resolve("{{token}}", nil)` → `"{{token}}"` — no crash, returned as-is
- [ ] Empty string: `resolve("", env)` → `""` — no crash
- [ ] No vars in string: `resolve("https://api.example.com", env)` → `"https://api.example.com"` — unchanged
- [ ] Malformed pattern `resolve("{{}}", env)` → `"{{}}"` — left as-is, no crash (pattern requires `\w+` inside)

## Failure cases
- [ ] Does NOT throw — returns string in all cases
- [ ] Does NOT crash on malformed input
- [ ] Does NOT return empty string when input is non-empty

## Constraints from CLAUDE.md
- [ ] `import Foundation` only — no `import SwiftUI`
- [ ] Returns a copy — original `string` parameter is not mutated (Swift strings are value types)
- [ ] Uses `NSRegularExpression` with pattern `\{\{(\w+)\}\}` — no third-party regex library
- [ ] No UI imports, no `@MainActor`

## Does NOT do (out of scope)
- [ ] Does not validate whether URLs are valid after substitution
- [ ] Does not substitute into header keys — only values
- [ ] Does not log or print substituted values (security)
- [ ] Does not modify `Request` directly — called per string by HTTPClient

## Integration
- [ ] Called by `HTTPClient.buildRequest(from:environment:)` before `URLRequest` is built
- [ ] `Environment` and `EnvVar` models (Phase 1) must compile before this file
