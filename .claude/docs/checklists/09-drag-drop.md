# Verification checklist — Drag-and-Drop Sidebar

## Happy path
- [ ] Drag a request row → drag preview appears
- [ ] Drop request onto a folder → request moves into that folder
- [ ] Folder auto-expands after drop to show moved item
- [ ] Order persists after restart (saved via `StorageService.saveWorkspaces`)

## Edge cases
- [ ] Drop folder onto itself → no-op (prevented)
- [ ] Drag request that is currently selected → selection preserved after move
- [ ] Drop on nested folder → item inserted into correct folder

## Implementation
- [ ] `.onDrag` on request rows returns `NSItemProvider` with UUID string
- [ ] `.onDrop` on folder rows accepts `UTType.text` and extracts UUID
- [ ] Tree mutation: extract item from old location, insert into target folder
- [ ] Workspace saved after successful drop

## Constraints
- [ ] No third-party imports (uses `UniformTypeIdentifiers` from Foundation)
- [ ] No hardcoded colors for drop targets

## Does NOT do
- [ ] Does not support reordering within the same folder (only move across folders)
- [ ] Does not support dragging folders
- [ ] Does not highlight drop target (relies on macOS native drop feedback)
