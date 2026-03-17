# Verification checklist — Workspace selector

## Inputs & outputs
- [ ] Part of `SidebarView` at `Views/Sidebar/SidebarView.swift`
- [ ] Reads `appState.workspaces` and `appState.selectedWorkspace`
- [ ] Writes `appState.selectedWorkspace` on selection change

## Happy path
- [ ] Shows active workspace name (e.g. "My Workspace") at the top of the sidebar
- [ ] Dropdown `Menu` lists all workspaces from `appState.workspaces`
- [ ] Selecting a workspace from dropdown updates `appState.selectedWorkspace`
- [ ] `+` button creates a new empty `Workspace` with name "New Workspace", appends to `appState.workspaces`, and selects it

## Edge cases
- [ ] When `appState.workspaces` is empty, shows "No Workspace" placeholder text
- [ ] When `appState.selectedWorkspace` is nil but workspaces exist, no workspace name shown (or first auto-selected)
- [ ] Creating a workspace when list is empty works without crash

## Failure cases
- [ ] Selecting a workspace that was deleted from the array does not crash — `selectedWorkspace` becomes nil

## Constraints from CLAUDE.md
- [ ] No third-party imports — SwiftUI only
- [ ] No hardcoded colors — uses `AppColors` tokens
- [ ] No hardcoded spacing — uses `AppSpacing` constants
- [ ] No business logic in view — only state mutations on AppState

## Does NOT do (out of scope)
- [ ] Does not persist workspaces to disk — StorageService integration is later
- [ ] Does not rename workspaces — that is context menu (separate task)
- [ ] Does not delete workspaces from the selector

## Integration
- [ ] `Workspace` model from Phase 1 used
- [ ] `AppState.selectedWorkspace` drives the request tree below
