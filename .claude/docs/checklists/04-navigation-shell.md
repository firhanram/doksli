# Verification checklist — NavigationSplitView shell + doksliApp wiring

## Inputs & outputs
- [ ] `ContentView` is a `View` struct at `Views/Shell/ContentView.swift`
- [ ] `ContentView` receives `AppState` via `@EnvironmentObject`
- [ ] `doksliApp.swift` creates `AppState` via `@StateObject` and injects with `.environmentObject`

## Happy path
- [ ] App launches and displays a 3-column `NavigationSplitView` (sidebar, content, detail)
- [ ] Sidebar column has `.navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)` — resizable down to 200px
- [ ] Content column fills remaining flexible space — no explicit width constraint
- [ ] `.frame(minWidth: 900, minHeight: 600)` applied on the root view — window cannot be resized below 900×600
- [ ] Sidebar background uses `AppColors.surface`
- [ ] Content background uses `AppColors.canvas`
- [ ] Detail background uses `AppColors.surface`

## Edge cases
- [ ] Narrowing the window collapses the sidebar first — standard macOS `NavigationSplitView` behavior
- [ ] Further narrowing collapses the detail column — columns collapse correctly
- [ ] `.preferredColorScheme(.light)` is present on ContentView inside the `WindowGroup` closure — light mode enforced
- [ ] App launches with empty `AppState()` (no workspaces) — shows placeholder content in all 3 columns without crash

## Failure cases
- [ ] `.environmentObject(appState)` is present on ContentView in `doksliApp.swift` — without it, `@EnvironmentObject` fails at runtime
- [ ] Missing `@EnvironmentObject` in ContentView → compile error — proves the property is declared

## Constraints from CLAUDE.md
- [ ] No third-party imports — SwiftUI only
- [ ] No hardcoded hex colors — uses `AppColors` tokens for all backgrounds
- [ ] No hardcoded spacing — uses `AppSpacing` constants for all padding
- [ ] Light mode only — `.preferredColorScheme(.light)` at WindowGroup level
- [ ] No business logic in Views — ContentView only owns layout and bindings

## Does NOT do (out of scope)
- [ ] Does not contain sidebar content — Phase 5
- [ ] Does not contain request editor — Phase 6
- [ ] Does not contain response viewer — Phase 7
- [ ] Does not load data from StorageService — wired in later phases

## Integration
- [ ] `AppState` injected from `doksliApp.swift` and accessible in ContentView
- [ ] `.toolbar { ToolbarView(appState:) }` attaches the toolbar
- [ ] `.commands { CommandGroup(replacing: .newItem) { } }` on WindowGroup disables default Cmd+N
- [ ] `#Preview` compiles with injected `AppState()`
