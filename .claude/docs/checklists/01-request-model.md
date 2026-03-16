# Verification checklist — Request + KVPair + HTTPMethod + RequestBody + Auth

## Inputs & outputs
- [ ] `Request` conforms to `Codable`, `Identifiable`; all 8 fields present: `id: UUID`, `name: String`, `method: HTTPMethod`, `url: String`, `params: [KVPair]`, `headers: [KVPair]`, `body: RequestBody`, `auth: Auth`
- [ ] `KVPair` conforms to `Codable`, `Identifiable`; fields: `id: UUID`, `key: String`, `value: String`, `enabled: Bool`
- [ ] `HTTPMethod` is `enum: String, Codable` with **exactly** 7 cases: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `OPTIONS`, `HEAD`
- [ ] `RequestBody` is `enum: Codable` with **exactly** 4 cases: `.none`, `.raw(String)`, `.formData([KVPair])`, `.urlEncoded([KVPair])`
- [ ] `Auth` is `enum: Codable` with **exactly** 4 cases: `.none`, `.bearer(String)`, `.basic(String, String)`, `.apiKey(String, String)`

## Happy path
- [ ] Round-trip `Request` with `method: .POST`, `url: "https://api.example.com/users"`, `body: .raw("{\"name\":\"Alice\"}")`, `auth: .bearer("sk_live_abc123")` → decoded struct has identical field values including the raw JSON string
- [ ] Round-trip `Request` with `body: .formData([KVPair(id: UUID(), key: "username", value: "alice", enabled: true), KVPair(id: UUID(), key: "role", value: "admin", enabled: false)])` → decoded formData array preserves both `KVPair` values with `enabled` booleans intact
- [ ] Round-trip `auth: .basic("user@example.com", "p@ssw0rd")` → decoded `.basic` case has both associated values in correct order

## Edge cases
- [ ] `params: []` and `headers: []` → encode as `"params":[]` and `"headers":[]`, not omitted keys
- [ ] `url: ""` → encodes and decodes without error; no URL validation at model layer
- [ ] `body: .none` and `auth: .none` → encode as discriminated JSON, decode back to `.none` without error
- [ ] `HTTPMethod.OPTIONS` and `HTTPMethod.HEAD` → raw values are `"OPTIONS"` and `"HEAD"` exactly (uppercase)

## Failure cases
- [ ] JSON with `"method": "CONNECT"` (unknown raw value) → `JSONDecoder` throws; does NOT default to `GET`
- [ ] JSON with `RequestBody` `"type"` key not in the 4 valid values → throws `DecodingError`
- [ ] `Auth` JSON with `"type":"apiKey"` but only 1 associated value present → throws `DecodingError`

## Constraints from CLAUDE.md
- [ ] `import Foundation` only — no `import SwiftUI`
- [ ] All fields `var` (mutable for SwiftUI bindings)
- [ ] File defines: `Request`, `KVPair`, `HTTPMethod`, `RequestBody`, `Auth` — nothing else
- [ ] No persistence logic in this file

## Does NOT do (out of scope)
- [ ] Does not validate URL format
- [ ] Does not serialize body to `Data` — that is `HTTPClient`'s job
- [ ] Does not inject `Authorization` header for `.bearer` auth — that is `HTTPClient`'s job

## Integration
- [ ] `Item.request(Request)` in `Workspace.swift` references this type
- [ ] `Response.headers: [KVPair]` in `Response.swift` references `KVPair` from this file
- [ ] `HistoryEntry.request: Request` in `HistoryEntry.swift` references this type
- [ ] `HTTPClient` (Phase 3) will read `method`, `url`, `params`, `headers`, `body`, `auth`
- [ ] `VariableResolver` (Phase 3) receives `url` and header values as `String` inputs
