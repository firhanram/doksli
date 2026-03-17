# Verification checklist — StorageService environments read/write

## Inputs & outputs
- [ ] `loadEnvironments() -> [Environment]` — no arguments, returns array (empty on failure)
- [ ] `saveEnvironments(_ environments: [Environment]) throws` — encodes and persists
- [ ] Both are `static` methods on `StorageService`

## Happy path
- [ ] `saveEnvironments([env1, env2])` then `loadEnvironments()` returns `[env1, env2]` with all vars intact
- [ ] `saveEnvironments([])` then `loadEnvironments()` returns `[]`
- [ ] Environments stored in `~/.doksli/v1/environments.json` — separate file from `workspaces.json`

## Edge cases
- [ ] `loadEnvironments()` when file does not exist → returns `[]`, does not crash
- [ ] `loadEnvironments()` when file contains `[]` → returns `[]`
- [ ] `loadEnvironments()` when file contains corrupt JSON → returns `[]`, does not crash
- [ ] `saveEnvironments` and `saveWorkspaces` do NOT write to the same file

## Failure cases
- [ ] `saveEnvironments` uses the same atomic write pattern (temp + rename) as workspaces
- [ ] If encoding fails → throws, does NOT write partial data

## Constraints from CLAUDE.md
- [ ] No third-party imports — Foundation only
- [ ] Atomic write: temp file then rename — not direct write
- [ ] File path is `~/.doksli/v1/environments.json`
- [ ] `JSONEncoder` / `JSONDecoder` used

## Does NOT do (out of scope)
- [ ] Does not activate or select an environment — that is `AppState.activeEnvironment`
- [ ] Does not validate variable keys or values
- [ ] Does not hold in-memory state

## Integration
- [ ] `Environment` and `EnvVar` models are `Codable` (Phase 1) and round-trip through JSON
- [ ] File is separate from `workspaces.json` — writing one does not affect the other
