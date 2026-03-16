# Verification checklist — Collection + Folder + Item (recursive enum)

## Inputs & outputs
- [ ] `Collection` conforms to `Codable`, `Identifiable`; fields: `id: UUID`, `name: String`, `items: [Item]`
- [ ] `Folder` conforms to `Codable`, `Identifiable`; fields: `id: UUID`, `name: String`, `items: [Item]`
- [ ] `Item` is `indirect enum` conforming to `Codable` with **exactly** 2 cases: `.folder(Folder)` and `.request(Request)`
- [ ] No additional cases on `Item`

## Happy path
- [ ] Flat: `Collection(id: UUID(), name: "Auth APIs", items: [.request(req)])` → round-trip produces `.request` case with identical `Request` fields
- [ ] Nested 3-level tree: Collection → Folder A (`items: [.folder(Folder B)]`) → Folder B (`items: [.request(req)]`) → encodes and decodes with all levels intact and correct case discrimination

## Edge cases
- [ ] `items: []` on both `Collection` and `Folder` → encodes as `"items":[]`, decodes to empty array
- [ ] A `Folder` containing only other `Folder` values (no request at leaf) → round-trip succeeds; no infinite loop
- [ ] 10-level nesting depth → encodes and decodes without stack overflow

## Failure cases
- [ ] JSON with an `Item` `"type"` value that is neither `"folder"` nor `"request"` → `JSONDecoder` throws `DecodingError`; does NOT silently skip the item
- [ ] `Item` JSON with `"type":"folder"` but missing the `"folder"` key → throws `DecodingError`

## Constraints from CLAUDE.md
- [ ] `import Foundation` only — no `import SwiftUI`
- [ ] `Item` enum has EXACTLY 2 cases
- [ ] File does not define `Request` struct (that belongs in `Request.swift`)

## Does NOT do (out of scope)
- [ ] Does not enforce a maximum nesting depth
- [ ] Does not contain move/reorder logic — that belongs in a future Service
- [ ] Does not contain `Workspace` definition (covered in checklist `01-workspace-model.md`)

## Integration
- [ ] `Workspace.collections: [Collection]` references `Collection`
- [ ] `Item.request(Request)` requires `Request` from `Request.swift` to compile first
- [ ] `Request.swift` must be compiled before `Workspace.swift`
