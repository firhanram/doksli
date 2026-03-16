# Verification checklist — Environment + EnvVar

## Inputs & outputs
- [ ] `Environment` conforms to `Codable`, `Identifiable`; fields: `id: UUID`, `name: String`, `variables: [EnvVar]`
- [ ] `EnvVar` conforms to `Codable`, `Identifiable`; fields: `id: UUID`, `key: String`, `value: String`, `enabled: Bool`
- [ ] `enabled: Bool` is present on `EnvVar` and is NOT optional — always in JSON

## Happy path
- [ ] Round-trip `Environment(id: UUID(), name: "Production", variables: [EnvVar(id: UUID(), key: "base_url", value: "https://api.example.com", enabled: true), EnvVar(id: UUID(), key: "token", value: "sk_live_abc", enabled: false)])` → decoded has both variables; second has `enabled: false`
- [ ] Round-trip `Environment(id: UUID(), name: "Empty Env", variables: [])` → `"variables":[]` in JSON, decodes to empty array

## Edge cases
- [ ] `key: ""` and `value: ""` on `EnvVar` → encodes and decodes; model does not validate non-empty
- [ ] `enabled: false` on all variables → all decode with `enabled: false`; no promotion to `true`
- [ ] `name: "Staging — EU"` (special characters) → encodes as UTF-8 JSON string, decodes back identically

## Failure cases
- [ ] JSON `EnvVar` missing `"enabled"` key → `JSONDecoder` throws; `enabled` has no default value
- [ ] JSON `Environment` with `"variables": null` → throws `DecodingError`; array cannot be null
- [ ] `EnvVar` JSON with `"enabled": 1` (integer not boolean) → throws `DecodingError`

## Constraints from CLAUDE.md
- [ ] `import Foundation` only — no `import SwiftUI`
- [ ] File contains only `Environment` and `EnvVar`
- [ ] No cross-references to `Request` or `Response` types

## Does NOT do (out of scope)
- [ ] Does not perform `{{key}}` substitution — that belongs in `VariableResolver`
- [ ] Does not filter disabled variables — callers filter by checking `.enabled`
- [ ] Does not validate that `key` is a valid identifier

## Integration
- [ ] `AppState.activeEnvironment: Environment?` holds the selected instance
- [ ] `VariableResolver` (Phase 3) reads `variables` array and filters by `enabled`
- [ ] `StorageService` (Phase 2) will persist `[Environment]` to `~/.doksli/v1/environments.json`
