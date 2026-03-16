# Verification checklist — Workspace model

## Inputs & outputs
- [ ] `Workspace` conforms to `Codable` and `Identifiable`
- [ ] Fields: `id: UUID`, `name: String`, `collections: [Collection]` — all `var`, not `let`
- [ ] No extra fields beyond what architecture.md specifies

## Happy path
- [ ] Encode `Workspace(id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!, name: "Personal", collections: [])` → decoded struct has identical `id`, `name`, and empty `collections`
- [ ] Encode a `Workspace` with `name: "Work API Testing"` containing 2 `Collection` values each with `items: []` → decoded preserves both collection names and their order

## Edge cases
- [ ] `name: ""` (empty string) — encodes and decodes without error; no validation at model layer
- [ ] `collections: []` (empty array) — encodes as `"collections":[]`, decodes back to empty `[Collection]`
- [ ] UUID round-trip: UUID encoded to JSON string decodes back to the identical `UUID` value

## Failure cases
- [ ] JSON with missing `"id"` key → `JSONDecoder` throws `DecodingError`; no silent default UUID
- [ ] JSON with `"id": "not-a-uuid"` → `JSONDecoder` throws `DecodingError.dataCorrupted`

## Constraints from CLAUDE.md
- [ ] `import Foundation` only — no `import SwiftUI`
- [ ] No third-party imports
- [ ] No hardcoded hex colors or spacing values (not applicable — no UI)

## Does NOT do (out of scope)
- [ ] Does not validate that `name` is non-empty
- [ ] Does not contain persistence logic — that belongs in `StorageService`
- [ ] Does not define `Collection`, `Folder`, or `Item` (those are in the same file `Workspace.swift` but covered by checklist `01-collection-model.md`)

## Integration
- [ ] `AppState.workspaces: [Workspace]` will hold decoded instances
- [ ] `StorageService` (Phase 2) will encode/decode `[Workspace]` to `workspaces.json`
- [ ] `Collection` type must compile before `Workspace` (same file, declared above `Workspace`)
