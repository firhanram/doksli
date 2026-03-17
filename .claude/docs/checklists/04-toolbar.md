# Verification checklist — ToolbarView: env selector + keyboard shortcuts

## Inputs & outputs
- [ ] Struct signature: `struct ToolbarView: ToolbarContent`
- [ ] File location: `Views/Shell/ToolbarView.swift`
- [ ] Takes `@ObservedObject var appState: AppState` as parameter

## Happy path
- [ ] Environment selector is a `Menu` component with `placement: .primaryAction` (right side of toolbar)
- [ ] When `activeEnvironment` is `nil`, menu label displays exactly `"No Environment"`
- [ ] When `activeEnvironment` is set to an `Environment` with `name = "Production"`, menu label displays `"Production"`
- [ ] Menu label includes `Image(systemName: "square.stack")` icon
- [ ] "No Environment" option in menu sets `appState.activeEnvironment = nil`
- [ ] All 6 keyboard shortcuts defined as `Button`s with `.keyboardShortcut()`:
  - `⌘↵` Send request (`.return`, `.command`)
  - `⌘N` New request (`"n"`, `.command`)
  - `⌘⇧N` New folder (`"n"`, `[.command, .shift]`)
  - `⌘K` Clear response (`"k"`, `.command`)
  - `⌘E` Env editor (`"e"`, `.command`)
  - `⌘D` Duplicate (`"d"`, `.command`)

## Edge cases
- [ ] Cmd+N does NOT open a new window — `.commands { CommandGroup(replacing: .newItem) { } }` in doksliApp overrides default
- [ ] Each shortcut button has an action closure that compiles (empty `{ }` is acceptable); actions do not trigger side effects on AppState or services in Phase 4
- [ ] All 6 keyboard shortcut buttons have `.keyboardShortcut()` modifiers registered

## Failure cases
- [ ] Without `.commands { CommandGroup(replacing: .newItem) { } }` in doksliApp, Cmd+N opens a new window instead of triggering the button

## Constraints from CLAUDE.md
- [ ] No third-party imports — SwiftUI only
- [ ] No hardcoded colors or spacing — uses `AppColors`, `AppSpacing`, `AppFonts` tokens
- [ ] No business logic — only UI declarations and stub actions
- [ ] Menu label text uses `AppFonts.body`, icon-text gap uses `AppSpacing.xs`

## Does NOT do (out of scope)
- [ ] Does not list environments in the menu dropdown — Phase 8
- [ ] Does not implement shortcut actions (send, new request, etc.) — later phases
- [ ] Does not contain an env editor sheet trigger — Phase 8

## Integration
- [ ] Used inside `.toolbar { ToolbarView(appState:) }` in ContentView
- [ ] Reads `appState.activeEnvironment` for menu label display
- [ ] Font and spacing tokens from `AppFonts` and `AppSpacing` used — no hardcoded values
