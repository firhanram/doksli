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
- Color mode: user-selectable (system/light/dark) via Settings > Appearance

## Docs

@docs/agent-workflow.md
@docs/design-system.md
@docs/architecture.md
@docs/file-structure.md
@docs/todos.md

## Commit rules

See `COMMITS.md` for the full spec. Summary:

- Follow [Conventional Commits](https://www.conventionalcommits.org): `<type>(<scope>): <subject>`
- Subject: imperative mood, sentence case, 72 chars max, no period
- Types: `feat` · `fix` · `refactor` · `test` · `docs` · `style` · `chore` · `perf` · `revert`
- Scope required for all types except `docs` and `chore` — scopes map to folder structure (e.g. `models`, `tokens`, `storage`, `shell`, `sidebar`, `request`, `response`, `env`, `history`, `config`)
- One logical change per commit — if the subject needs "and", split it
- Footer records reviewer sign-off after `APPROVED`: `Reviewed-by:` + `Checklist:`

---

## Hard rules — never break these

- Never hardcode hex colors — use `AppColors` tokens only
- Never hardcode spacing — use `AppSpacing` constants only
- Never add third-party packages — Foundation + SwiftUI only
- Never write directly to a file — atomic write (temp file + rename)
- Never mutate a `Request` before send — `VariableResolver` returns a resolved copy
- Never use `TabView` for request/response tabs — use custom segment control
- All colors must use `AppColors` adaptive tokens — never bypass with raw hex
- Never put business logic in Views — belongs in Services

## Layout reference

See `docs/doksli.png` for the target UI. Key layout decisions visible in the screenshot:

**3-column `NavigationSplitView`:**
- **Left sidebar** — workspace selector dropdown + tab bar (Collections / History / Env) + scrollable tree (`OutlineGroup`) + `+ New request` button pinned at bottom
- **Center** — request name + Save/Duplicate buttons · URL bar (method picker + URL field + Send button) · request tab bar (Params / Headers / Body / Auth / Pre-req) · KV editor · response stats bar (status · ms · KB · Copy / Save / Clear) · response tab bar (Body / Headers / Cookies / Raw / Preview) · JSON tree viewer
- **Right panel** — response headers list + recent requests history with method badge + URL + status + time

**URL bar:** variables like `{{page}}` rendered in brand orange (`AppColors.brandHover`), non-var text in default color.

**Tab bars:** custom segment control (NOT `TabView`) — active tab has underline in `AppColors.brand`.

**Method badges:** colored pill — GET green, POST blue, PUT amber, DELETE red, PATCH purple, OPTIONS teal, HEAD gray.

**Response stats bar:** status code chip colored by range (2xx green / 3xx amber / 4xx–5xx red) + duration in ms + size in KB.

**Environment selector:** toolbar `Menu` top-right showing active environment name (e.g. "Production").

**Sidebar tree:** section headers in eyebrow style (all-caps, `AppFonts.eyebrow`) · folders expandable with chevron · active request row highlighted with `AppColors.brandTint50` background.

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
