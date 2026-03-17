# Verification checklist — StorageService workspaces read/write

## Inputs & outputs
- [ ] `loadWorkspaces() -> [Workspace]` — no arguments, returns array (empty on failure)
- [ ] `saveWorkspaces(_ workspaces: [Workspace]) throws` — encodes and persists
- [ ] Both are `static` methods on `StorageService`

## Happy path
- [ ] `saveWorkspaces([ws1, ws2])` then `loadWorkspaces()` returns `[ws1, ws2]` with all fields intact
- [ ] `saveWorkspaces([])` then `loadWorkspaces()` returns `[]`
- [ ] First call to `saveWorkspaces` creates `~/.doksli/v1/workspaces.json` — file did not exist before
- [ ] Second call to `saveWorkspaces` overwrites `~/.doksli/v1/workspaces.json` atomically

## Edge cases
- [ ] `loadWorkspaces()` when file does not exist → returns `[]`, does not crash
- [ ] `loadWorkspaces()` when file contains `[]` → returns `[]`
- [ ] `loadWorkspaces()` when file contains corrupt JSON (e.g. `{broken`) → returns `[]`, does not crash

## Failure cases
- [ ] `saveWorkspaces` writes to a `.tmp` file first, then renames — never writes directly to target
- [ ] If encoding fails → throws, does NOT write partial data

## Constraints from CLAUDE.md
- [ ] No third-party imports — Foundation only
- [ ] Atomic write pattern: encode → temp file → rename (not `data.write(to: target)` directly)
- [ ] File path is `~/.doksli/v1/workspaces.json` — NOT inside the app bundle
- [ ] `JSONEncoder` / `JSONDecoder` used — no custom serialization

## Does NOT do (out of scope)
- [ ] Does not create the `~/.doksli/v1/` directory — that is done in `doksliApp.swift` on launch
- [ ] Does not migrate data schemas — VERSION file is separate
- [ ] Does not hold in-memory state — purely file I/O, no caching

## Integration
- [ ] `Workspace` model is `Codable` (Phase 1) and round-trips through JSON correctly
- [ ] Called by `AppState` (Phase 4) on load and after mutations
