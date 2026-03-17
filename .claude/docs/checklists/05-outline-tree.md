# Verification checklist — OutlineGroup request tree

## Inputs & outputs
- [ ] Renders the `items: [Item]` tree from the selected workspace's collections
- [ ] Uses `OutlineGroup` or recursive `ForEach` for arbitrary-depth rendering
- [ ] Selection updates `appState.selectedRequest`

## Happy path
- [ ] Folder with 2 requests renders folder row + 2 request rows when expanded
- [ ] Nested folders (3+ levels deep) render correctly without crash
- [ ] Clicking a request row sets `appState.selectedRequest` to that request
- [ ] Active request row has `AppColors.brandTint50` background highlight
- [ ] Expand/collapse on folders works via disclosure indicator (chevron)

## Edge cases
- [ ] Empty workspace (no collections) shows empty state or placeholder
- [ ] Collection with no items shows collection header but no children
- [ ] Deeply nested structure (5+ levels) does not crash or break layout

## Failure cases
- [ ] Selecting a request then switching workspace clears or updates `selectedRequest`

## Constraints from CLAUDE.md
- [ ] No third-party imports — SwiftUI only
- [ ] No hardcoded colors — uses `AppColors` tokens
- [ ] No hardcoded spacing — uses `AppSpacing` constants
- [ ] Active request highlighted with `AppColors.brandTint50` background

## Does NOT do (out of scope)
- [ ] Does not handle drag-and-drop — Phase 9
- [ ] Does not handle rename inline — context menu triggers rename

## Integration
- [ ] `Item` recursive enum, `Folder`, `Collection` from Workspace.swift
- [ ] `Request` from Request.swift
- [ ] `FolderRow` and `RequestRow` used as row views
- [ ] `MethodBadge` used inside `RequestRow`
