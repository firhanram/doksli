# Verification checklist — Storage directory scheme

## Inputs & outputs
- [ ] `doksliApp.swift` calls storage setup in `init()` before any view appears
- [ ] Setup uses `FileManager.default.homeDirectoryForCurrentUser` to compute path — NOT a hardcoded path
- [ ] Target directory: `~/.doksli/v1/` (two levels deep)
- [ ] VERSION file written at `~/.doksli/v1/VERSION` with content `"1"`

## Happy path
- [ ] After first app launch, `~/.doksli/v1/` directory exists on disk
- [ ] After first app launch, `~/.doksli/v1/VERSION` exists and contains exactly `"1"`
- [ ] On second launch (directory already exists), app launches without error — `createDirectory` is called with `withIntermediateDirectories: true` so it does not throw on existing dir

## Edge cases
- [ ] If `~/.doksli/v1/` already exists (e.g., second launch), directory creation does NOT throw — `try?` or `withIntermediateDirectories: true` handles this silently
- [ ] If `VERSION` file already exists, it is NOT overwritten — existence check guards the write
- [ ] Directory is at `~/.doksli/v1/` — NOT inside the app bundle

## Failure cases
- [ ] If directory creation fails (e.g., permissions) — error is swallowed with `try?`, app does NOT crash
- [ ] Storage setup code does NOT use `throws` or propagate errors to the SwiftUI scene lifecycle

## Constraints from CLAUDE.md
- [ ] Uses Foundation only — no SwiftUI import in the storage setup function
- [ ] No atomic write pattern needed for VERSION (it's a one-time write of static content)
- [ ] Storage setup is in `doksliApp.swift` App `init()` — not in a View

## Does NOT do (out of scope)
- [ ] Does not create `workspaces.json`, `environments.json`, or `history.json` — those are `StorageService`'s job (Phase 2)
- [ ] Does not read or parse VERSION — write only at this stage
- [ ] Does not check for schema migration — that belongs in a future migration system

## Integration
- [ ] `StorageService` (Phase 2) will assume `~/.doksli/v1/` exists — this Phase 0 task guarantees it
- [ ] `StorageService` will write to `~/.doksli/v1/workspaces.json` etc., so the directory must pre-exist
