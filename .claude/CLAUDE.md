# Doksli

Native macOS API client. SwiftUI only. Zero third-party dependencies.

---

## Agent rule — read this first

Before starting any task:

1. Read the task in `docs/todos.md`
2. Read the relevant section of the referenced doc
3. **Write a verification checklist** at `docs/checklists/<task-slug>.md`
4. Get the checklist reviewed by a second agent
5. Only then write code

A task is not done until a second agent has run the checklist independently and issued `APPROVED`.
See `docs/agent-workflow.md` for the full protocol and checklist format.

---

## Quick facts

- Platform: macOS 13+
- Bundle ID: `com.firhanram.doksli`
- Language: Swift 5.9+
- UI: SwiftUI, `NavigationSplitView`
- Color mode: light only — `.preferredColorScheme(.light)` at `WindowGroup`

## Docs

@docs/agent-workflow.md
@docs/design-system.md
@docs/architecture.md
@docs/file-structure.md
@docs/todos.md

## Hard rules — never break these

- Never hardcode hex colors — use `AppColors` tokens only
- Never hardcode spacing — use `AppSpacing` constants only
- Never add third-party packages — Foundation + SwiftUI only
- Never write directly to a file — atomic write (temp file + rename)
- Never mutate a `Request` before send — `VariableResolver` returns a resolved copy
- Never use `TabView` for request/response tabs — use custom segment control
- Light mode only — never remove `.preferredColorScheme(.light)`
- Never put business logic in Views — belongs in Services

## Current phase

See `docs/todos.md` for full checklist.

## Key files

| File | Purpose |
|---|---|
| `Resources/AppColors.swift` | All color tokens |
| `Resources/AppSpacing.swift` | All spacing constants |
| `Resources/AppFonts.swift` | Font + size constants |
| `Services/HTTPClient.swift` | URLSession wrapper |
| `Services/VariableResolver.swift` | `{{var}}` substitution |
| `Services/StorageService.swift` | JSON persistence |
| `Views/Shell/AppState.swift` | Global observable state |
