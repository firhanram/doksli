# Commit rules

All commits follow the [Conventional Commits](https://www.conventionalcommits.org) spec.
Every commit message is machine-readable and human-scannable.

---

## Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Rules

- Subject line: 72 characters max
- Subject: sentence case, no period at the end
- Type: lowercase always
- Scope: lowercase, kebab-case
- Body: wrap at 72 characters, explain *why* not *what*
- Footer: used for breaking changes and issue references
- Empty line between subject, body, and footer — always

---

## Types

| Type | When to use |
|---|---|
| `feat` | A new feature visible to the user |
| `fix` | A bug fix |
| `refactor` | Code change that is not a feat or fix |
| `test` | Adding or updating tests only |
| `docs` | Documentation only — md files, code comments |
| `style` | Formatting, spacing, no logic change |
| `chore` | Build config, project setup, tooling |
| `perf` | Performance improvement |
| `revert` | Reverts a previous commit |

**Rules:**
- `feat` and `fix` appear in the changelog — all others do not
- Never use `feat` for internal refactors even if they "enable" a feature
- Never use `chore` as a catch-all — if it has a real type, use it

---

## Scopes

Scopes map directly to the folder structure in `file-structure.md`.

| Scope | Maps to |
|---|---|
| `models` | `Models/` — any data model file |
| `storage` | `Services/StorageService.swift` |
| `http` | `Services/HTTPClient.swift` |
| `resolver` | `Services/VariableResolver.swift` |
| `importer` | `Services/PostmanImporter.swift` |
| `shell` | `Views/Shell/` |
| `sidebar` | `Views/Sidebar/` |
| `request` | `Views/Request/` |
| `response` | `Views/Response/` |
| `env` | `Views/Environment/` |
| `history` | `Views/History/` |
| `tokens` | `Resources/AppColors`, `AppFonts`, `AppSpacing` |
| `app` | `App/DoksliApp.swift` |
| `tests` | `DoksliTests/` |
| `docs` | `docs/` and `CLAUDE.md` |
| `checklists` | `docs/checklists/` |
| `config` | Xcode project settings, entitlements, `Info.plist` |

Scope is required for all types except `docs` and `chore`.

---

## Subject line

- Imperative mood — "add", "fix", "remove", not "added", "fixes", "removed"
- Sentence case — first word capitalised, rest lowercase
- No period at the end
- Describes what the commit does, not what you did

```
// ✅ correct
feat(resolver): Add {{var}} substitution with disabled-var skip

// ❌ wrong — past tense
feat(resolver): Added variable substitution

// ❌ wrong — period at end
feat(resolver): Add variable substitution.

// ❌ wrong — vague
feat(resolver): Update resolver

// ❌ wrong — all caps scope
feat(Resolver): Add variable substitution
```

---

## Body

Optional but required when:
- The *why* is not obvious from the subject line
- The commit changes behaviour in a subtle way
- A technical decision was made that future readers need to understand

```
feat(storage): Use atomic write to prevent data corruption

Direct file writes leave a window where the app can crash
mid-write and produce a corrupt or zero-byte JSON file.

Writing to a temp file in the same directory then calling
rename() is atomic on APFS — the file either fully exists
or does not, with no partial state.
```

---

## Footer

### Breaking changes

```
feat(models): Replace body: String with body: RequestBody enum

BREAKING CHANGE: Request.body is now RequestBody enum, not String.
Migrate: .body = "raw string" → .body = .raw("raw string")
```

### Issue references

```
fix(http): Handle URLSession cancellation without crashing

Fixes #42
```

### Reviewer sign-off

After a task is `APPROVED` in the agent workflow, the footer records it:

```
feat(resolver): Add {{var}} substitution with disabled-var skip

Reviewed-by: Agent-2
Checklist: docs/checklists/03-variable-resolver.md
```

---

## Scoping multiple files

If a commit touches files across scopes, use the primary scope.
If truly cross-cutting, omit the scope entirely.

```
// touches models + storage together
feat(storage): Add HistoryEntry persistence with ring buffer

// cross-cutting — no scope
refactor: Extract KVPair into shared type used by Request and Response
```

---

## Examples by phase

### Phase 0 — Setup

```
chore(config): Add outgoing network entitlement to sandbox
chore(config): Set minimum deployment target to macOS 13
chore(tokens): Create AppColors with full design system palette
chore(tokens): Create AppFonts with SF Pro and SF Mono roles
chore(tokens): Create AppSpacing with scale and radius tokens
```

### Phase 1 — Models

```
feat(models): Add Workspace and Collection with recursive Item enum
feat(models): Add Request with HTTPMethod, RequestBody, and Auth enums
feat(models): Add KVPair as shared key-value type
feat(models): Add Response with Codable conformance for history
feat(models): Add Environment and EnvVar with enabled toggle
feat(models): Add HistoryEntry as snapshot of Request and Response
```

### Phase 2 — Storage

```
feat(storage): Add atomic write pattern for workspaces.json
feat(storage): Add environments persistence separate from workspaces
feat(storage): Add history ring buffer capped at 100 entries
test(storage): Add round-trip encode/decode tests for all models
```

### Phase 3 — HTTP + Resolver

```
feat(resolver): Add {{var}} substitution with disabled-var skip
feat(resolver): Leave unknown variables as-is without crashing
feat(http): Add URLRequest builder for all 7 HTTP methods
feat(http): Add URLSession send with ContinuousClock timing
feat(http): Add HTTPURLResponse mapping to Response model
test(http): Add integration tests against httpbin.org
```

### Phase 4 — Shell

```
feat(shell): Add NavigationSplitView with 3-column layout
feat(shell): Add AppState as MainActor observable source of truth
feat(shell): Add environment selector Menu to toolbar
chore(app): Enforce light mode with preferredColorScheme at WindowGroup
```

### Phase 5 — Sidebar

```
feat(sidebar): Add workspace selector with dropdown and create button
feat(sidebar): Add OutlineGroup tree for recursive Item enum
feat(sidebar): Add MethodBadge with colors from AppColors tokens
feat(sidebar): Add context menu for rename, duplicate, delete, move
```

### Phase 6 — Request editor

```
feat(request): Add URL bar with method picker and Send button
feat(request): Add custom TabBarView segment control
feat(request): Add KVEditor shared by Params and Headers tabs
feat(request): Add BodyEditor with none, raw, form-data, urlEncoded modes
feat(request): Add AuthEditor with bearer token auto-injection
feat(request): Add {{var}} syntax highlighting in URL field
```

### Phase 7 — Response viewer

```
feat(response): Add stats bar with status, duration, and size chips
feat(response): Add JSONTreeView with recursive expand and collapse
feat(response): Add syntax colors for keys, strings, numbers, booleans
feat(response): Add response headers read-only list with copy on click
feat(response): Add raw body view with monospaced font and copy-all
```

### Phase 8 — Environments

```
feat(env): Add EnvEditorSheet with KVEditor and enabled toggles
feat(env): Add EnvSelectorMenu to toolbar with no-environment option
feat(env): Add Postman environment JSON import via NSOpenPanel
feat(env): Add resolved variable tooltip on {{var}} tokens in URL bar
```

### Phase 9 — Polish

```
feat(history): Add history panel grouped by date with request reload
feat(shell): Wire all keyboard shortcuts across the app
feat(sidebar): Add drag-and-drop reorder within and across folders
feat(shell): Add empty states for no collection, no request, no response
fix(http): Handle network error and SSL failure without crashing
feat(app): Add app icon with brand color to Assets.xcassets
```

---

## What never goes in a commit message

- "WIP" — finish the work, then commit
- "Fix bug" — which bug, how, why
- "Update file" — describe what changed
- "Per review" — describe the actual change made
- "Misc changes" — split into separate commits
- Emoji — not in the subject line

---

## Commit size

One logical change per commit.

```
// ✅ correct — two separate commits
feat(models): Add Request model with all associated enums
test(models): Add encode/decode round-trip for Request

// ❌ wrong — two concerns in one commit
feat(models): Add Request model and tests
```

If you cannot describe a commit in one subject line without using "and",
it should be two commits.
