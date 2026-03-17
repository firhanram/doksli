# Verification checklist — Keyboard Shortcuts

## Inputs & outputs
- [ ] All 6 shortcuts defined in `ToolbarView.swift` with non-empty actions
- [ ] Actions centralized in `AppState` methods, called from `ToolbarView`

## Happy path
- [ ] `⌘↵` (Cmd+Return) sends the current request → response appears
- [ ] `⌘N` (Cmd+N) creates a new GET request in the current workspace → request appears in sidebar and is selected
- [ ] `⌘⇧N` (Cmd+Shift+N) creates a new folder in the current workspace → folder appears in sidebar
- [ ] `⌘K` (Cmd+K) clears the response panel → response and error both cleared
- [ ] `⌘E` (Cmd+E) opens the environment editor sheet
- [ ] `⌘D` (Cmd+D) duplicates the selected request → copy appears after original with "(Copy)" suffix

## Edge cases
- [ ] `⌘↵` with no request selected → no-op, no crash
- [ ] `⌘↵` with empty URL → no-op, no crash
- [ ] `⌘↵` while loading → no-op (guard prevents double-send)
- [ ] `⌘N` with no workspace selected → no-op, no crash
- [ ] `⌘⇧N` with no workspace selected → no-op, no crash
- [ ] `⌘D` with no request selected → no-op, no crash
- [ ] `⌘K` with no response → no-op, no crash

## AppState methods
- [ ] `sendCurrentRequest()` — reads `selectedRequest`, calls `HTTPClient.send`, stores response/error
- [ ] `addNewRequest(method:)` — creates request in first collection, selects it
- [ ] `addNewFolder()` — creates folder in first collection
- [ ] `duplicateSelectedRequest()` — duplicates `selectedRequest` with new UUID
- [ ] `clearResponse()` — sets `pendingResponse = nil`, `lastError = nil`

## Constraints from CLAUDE.md
- [ ] No third-party imports
- [ ] Shortcuts defined in `ToolbarView.swift` (single place per architecture)
- [ ] No business logic in Views — actions live in `AppState`

## Does NOT do (out of scope)
- [ ] Does not add new shortcuts beyond the 6 defined
- [ ] Does not handle system shortcut conflicts (relies on SwiftUI precedence)

## Integration
- [ ] `SidebarView` delegates `addNewRequest`/`addNewFolder` to `appState` methods
- [ ] `URLBarView.sendRequest()` delegates to `appState.sendCurrentRequest()`
- [ ] `ToolbarView` shortcuts call `appState` methods directly
