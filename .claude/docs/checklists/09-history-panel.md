# Verification checklist — History Panel

## Inputs & outputs
- [ ] `HistoryView` displays `appState.historyEntries` grouped by date
- [ ] `AppState.recordHistory(request:response:)` creates entry, persists, updates UI
- [ ] `AppState.loadHistory()` reads from `StorageService.loadHistory()`

## Happy path
- [ ] Send GET request → entry appears in History tab with method badge, URL, status code, duration, time
- [ ] Send POST request → entry appears with POST badge and correct status
- [ ] Click history entry → `selectedRequest` and `pendingResponse` are populated, response appears

## Date grouping
- [ ] Entries from today grouped under "TODAY" header
- [ ] Entries from yesterday grouped under "YESTERDAY" header
- [ ] Older entries grouped under formatted date (e.g. "MAR 15, 2026")
- [ ] Within each group, entries sorted newest-first

## History row content
- [ ] `MethodBadge` shows correct method with design system colors
- [ ] URL displayed in mono font, protocol stripped, truncated to 1 line
- [ ] Status code chip: 2xx green, 3xx amber, 4xx/5xx red
- [ ] Duration shown in ms
- [ ] Timestamp shown as time (e.g. "2:30 PM")

## Ring buffer
- [ ] History capped at 100 entries (via `StorageService.appendHistory`)
- [ ] 101st entry drops the oldest
- [ ] Order is newest-first

## Sidebar integration
- [ ] Sidebar has Collections | History tab bar using `TabBarView`
- [ ] Switching tabs shows correct content
- [ ] "New Request" button hidden when History tab is active
- [ ] Collections tab is default

## Empty state
- [ ] Empty history shows clock icon + "No history yet" message
- [ ] Uses `AppColors.textFaint` for icon, `AppColors.textTertiary` for text

## Persistence
- [ ] History persists to `~/.doksli/v1/history.json`
- [ ] History loads on app launch via `.task` in `ContentView`
- [ ] Restart app → history entries still present

## Storage of original request
- [ ] History stores original request with `{{vars}}` (not resolved copy)
- [ ] Reloading history entry works with current environment

## Constraints from CLAUDE.md
- [ ] No third-party imports
- [ ] No hardcoded colors — uses `AppColors` tokens only
- [ ] No hardcoded spacing — uses `AppSpacing` constants only
- [ ] Reuses existing `MethodBadge` component
- [ ] Reuses existing `TabBarView` component

## Does NOT do (out of scope)
- [ ] Does not record failed requests (errors) — only successful responses
- [ ] Does not allow deleting individual history entries
- [ ] Does not allow clearing all history

## Integration
- [ ] `AppState.sendCurrentRequest()` calls `recordHistory` after successful response
- [ ] `ContentView` calls `appState.loadHistory()` on launch
- [ ] `SidebarView` renders `HistoryView` when History tab is active
