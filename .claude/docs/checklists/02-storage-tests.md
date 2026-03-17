# Verification checklist — StorageService round-trip test suite

## Inputs & outputs
- [ ] Tests use Swift Testing (`import Testing`, `@Test func`, `#expect`) — consistent with existing test files
- [ ] Tests import `@testable import doksli` to access `StorageService`
- [ ] Each test passes an isolated temp directory to `StorageService` methods — does NOT read/write `~/.doksli/v1/`

## Happy path
- [ ] Workspace round-trip: save a `Workspace` with nested `Collection` → `Folder` → `Request`, reload it, decoded value equals original (id, name, all nested fields)
- [ ] Request with `.raw("{\"key\":\"value\"}")` body round-trips: decoded `body` equals original
- [ ] Request with `.formData([KVPair(id:, key:"field", value:"val", enabled:true)])` body round-trips: decoded `body` equals original
- [ ] Request with `.urlEncoded([KVPair(id:, key:"q", value:"hello", enabled:true)])` body round-trips: decoded `body` equals original
- [ ] Request with `.none` body round-trips: decoded `body` equals `.none`
- [ ] Response with binary body `Data([0xFF, 0xFE, 0x00])` survives encode/decode cycle: decoded `body` is identical to `Data([0xFF, 0xFE, 0x00])`
- [ ] History ring buffer: after appending 101 entries with IDs 0–100, `loadHistory()` returns exactly 100 entries; entry with ID=100 is at index 0; entry with ID=0 is absent

## Edge cases
- [ ] `loadWorkspaces()` with missing file → `[]`
- [ ] `loadEnvironments()` with missing file → `[]`
- [ ] `loadHistory()` with missing file → `[]`
- [ ] Corrupt JSON written to workspaces file → `loadWorkspaces()` returns `[]`, no crash
- [ ] Corrupt JSON written to history file → `loadHistory()` returns `[]`, no crash

## Failure cases
- [ ] After `saveWorkspaces` completes, `workspaces.json` exists in the test dir and contains decodable JSON
- [ ] After `saveWorkspaces([ws1])` and `saveEnvironments([env1])`, verify `workspaces.json` contains `[ws1]` AND `environments.json` contains `[env1]` — both files are independent

## Constraints from CLAUDE.md
- [ ] No third-party imports — Foundation + Testing only
- [ ] Tests do NOT read from or write to `~/.doksli/v1/` — use temp paths
- [ ] Tests are deterministic — UUIDs are pre-seeded, not compared as random values

## Does NOT do (out of scope)
- [ ] Does not test network calls
- [ ] Does not test UI or AppState
- [ ] Does not test PostmanImporter

## Integration
- [ ] All Phase 1 model `Codable` implementations exercised: `Workspace`, `Collection`, `Item`, `Folder`, `Request`, `KVPair`, `RequestBody`, `Auth`, `Response`, `Environment`, `EnvVar`, `HistoryEntry`
- [ ] `StorageService` methods called directly (not via mocks)
