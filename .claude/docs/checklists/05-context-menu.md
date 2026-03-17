# Verification checklist — Context menu

## Inputs & outputs
- [ ] `.contextMenu { }` attached to request rows and folder rows in the sidebar tree
- [ ] Actions mutate `appState.workspaces` (and nested collections/items)

## Happy path
- [ ] Right-click on a request row shows: Rename, Duplicate, Delete
- [ ] Right-click on a folder row shows: Rename, Delete, New Request Inside
- [ ] "Duplicate" creates a copy of the request with a new UUID and "(Copy)" suffix, inserted after the original
- [ ] "Delete" removes the item from its parent's items array
- [ ] "New Request Inside" on a folder appends a new blank `Request` inside that folder

## Edge cases
- [ ] Deleting the currently selected request sets `appState.selectedRequest = nil`
- [ ] Duplicating a request does not select the duplicate automatically
- [ ] Context menu on deeply nested items (3+ levels) works correctly

## Failure cases
- [ ] Deleting the last item in a folder leaves the folder with empty `items: []` — does not crash
- [ ] Renaming produces no crash (rename UI is a simple alert or inline edit)

## Constraints from CLAUDE.md
- [ ] No third-party imports — SwiftUI only
- [ ] No hardcoded colors or spacing
- [ ] Actions mutate AppState — no direct StorageService calls from the view

## Does NOT do (out of scope)
- [ ] Does not handle drag-and-drop reordering — Phase 9
- [ ] Does not persist changes to disk — StorageService wired later
- [ ] Does not show "Move to folder" submenu — Phase 9

## Integration
- [ ] Mutates `appState.workspaces` which triggers view updates via `@Published`
- [ ] Uses `Request`, `Folder`, `Item` types from Phase 1 models
