# Development todos

Work top to bottom. Never skip a phase — each one is a dependency of the next.

**Before touching any task, read `docs/agent-workflow.md`.**
Every task requires a verification checklist written and approved before code starts.

## Status markers

| Marker | Meaning |
|---|---|
| `[ ]` | Not started |
| `[~]` | Checklist written, awaiting checklist review |
| `[b]` | Building — checklist approved, code in progress |
| `[s]` | Self-check done, awaiting Reviewer |
| `[x]` | ✅ APPROVED — done |
| `[!]` | ❌ NEEDS CHANGES — returned by Reviewer |

---

## Phase 0 — Project setup
> Must be done before writing any Swift code.

- [ ] Create macOS app target in Xcode
  - Checklist: `docs/checklists/00-xcode-setup.md`
  - Verify: SwiftUI lifecycle · macOS 13+ · bundle ID `com.yourname.doksli` · sandbox entitlement for outgoing connections

- [ ] Create storage directory scheme
  - Checklist: `docs/checklists/00-storage-scheme.md`
  - Verify: `~/.doksli/v1/` exists on first launch · `VERSION` file written · directory not inside app bundle

- [ ] Set up folder structure
  - Checklist: `docs/checklists/00-folder-structure.md`
  - Verify: matches `file-structure.md` exactly · no extra files · no missing groups in Xcode

- [ ] `AppColors.swift`
  - Checklist: `docs/checklists/00-appcolors.md`
  - Verify: every token from `design-system.md` is present · no hardcoded hex anywhere else · compiles clean

- [ ] `AppFonts.swift`
  - Checklist: `docs/checklists/00-appfonts.md`
  - Verify: all 5 font roles present · SF Mono for mono role · no `UIFont` / `NSFont` used directly in views

- [ ] `AppSpacing.swift`
  - Checklist: `docs/checklists/00-appspacing.md`
  - Verify: all 7 spacing values + 5 radius values present · all typed as `CGFloat` · no magic numbers in views

---

## Phase 1 — Data models
> Define all `Codable` structs before writing a single View.

- [ ] `Workspace` model
  - Checklist: `docs/checklists/01-workspace-model.md`
  - Verify: `Codable` · `Identifiable` · all fields match `architecture.md` · encode→decode round-trip passes

- [ ] `Collection` + `Folder` + recursive `Item` enum
  - Checklist: `docs/checklists/01-collection-model.md`
  - Verify: `Item` enum has exactly `.folder(Folder)` and `.request(Request)` · arbitrary depth encodes correctly · no infinite loop risk

- [ ] `Request` + `KVPair` + `HTTPMethod` + `RequestBody` + `Auth`
  - Checklist: `docs/checklists/01-request-model.md`
  - Verify: all associated enums are `Codable` · `RequestBody` covers all 4 cases · `Auth` covers all 4 cases

- [ ] `Response` model
  - Checklist: `docs/checklists/01-response-model.md`
  - Verify: `Codable` (needed for history) · `body: Data` encodes as base64 · all fields present

- [ ] `Environment` + `EnvVar`
  - Checklist: `docs/checklists/01-environment-model.md`
  - Verify: `Codable` · `enabled: Bool` present on `EnvVar` · encode→decode round-trip passes

- [ ] `HistoryEntry`
  - Checklist: `docs/checklists/01-history-entry-model.md`
  - Verify: `Codable` · snapshot — not a reference to live `Request` · `timestamp: Date` encodes as ISO8601

---

## Phase 2 — Storage service
> Write and verify persistence before any UI.

- [ ] `StorageService` — workspaces read/write
  - Checklist: `docs/checklists/02-storage-workspaces.md`
  - Verify: atomic write (temp + rename) · file created on first save · loads correctly after restart simulation · corrupt file returns empty, does not crash

- [ ] `StorageService` — environments read/write
  - Checklist: `docs/checklists/02-storage-environments.md`
  - Verify: separate file from workspaces · same atomic write pattern · empty environments returns `[]`

- [ ] `StorageService` — history ring buffer
  - Checklist: `docs/checklists/02-storage-history.md`
  - Verify: capped at 100 · 101st entry drops oldest · order is newest-first · empty returns `[]`

- [ ] `XCTest` round-trip suite
  - Checklist: `docs/checklists/02-storage-tests.md`
  - Verify: Workspace round-trip · Request with all body types round-trip · Response with binary body round-trip

---

## Phase 3 — HTTP client & variable resolver
> Pure Swift. No SwiftUI dependency. Test in isolation.

- [ ] `VariableResolver.resolve()`
  - Checklist: `docs/checklists/03-variable-resolver.md`
  - Verify: known vars replaced · unknown vars left as-is · disabled vars skipped · nil env safe · original string not mutated
  - See example checklist in `agent-workflow.md`

- [ ] `HTTPClient.buildRequest(from:environment:)`
  - Checklist: `docs/checklists/03-http-client-build.md`
  - Verify: all 7 methods produce correct `httpMethod` · query params appended · headers set · body encoded per `RequestBody` · vars resolved before building

- [ ] `HTTPClient.send(_:)`
  - Checklist: `docs/checklists/03-http-client-send.md`
  - Verify: `async throws` · `ContinuousClock` wraps session call · network error propagates · cancellation handled

- [ ] Response mapping `HTTPURLResponse` → `Response`
  - Checklist: `docs/checklists/03-response-mapping.md`
  - Verify: status code extracted · all headers captured as `[KVPair]` · `sizeBytes` = `data.count` · `durationMs` is wall-clock time

- [ ] Integration tests against `httpbin.org`
  - Checklist: `docs/checklists/03-integration-tests.md`
  - Verify: `GET /get` returns 200 · `POST /post` with JSON body echoes body · headers round-trip · `DELETE /delete` returns 200

---

## Phase 4 — App shell & navigation
> Build skeleton with placeholder content before filling in real views.

- [ ] `NavigationSplitView` shell
  - Checklist: `docs/checklists/04-navigation-shell.md`
  - Verify: 3 columns present · sidebar 200px min · content flexible · window min size `900×600` · columns collapse correctly

- [ ] `AppState` observable object
  - Checklist: `docs/checklists/04-app-state.md`
  - Verify: all 6 published properties present · `@MainActor` annotation · injected via `@StateObject` at root · no business logic inside `AppState`

- [ ] Toolbar
  - Checklist: `docs/checklists/04-toolbar.md`
  - Verify: env selector `Menu` on right · keyboard shortcuts defined · `.preferredColorScheme(.light)` at `WindowGroup`

---

## Phase 5 — Sidebar
> Build before request editor — needed to load and switch requests.

- [ ] Workspace selector
  - Checklist: `docs/checklists/05-workspace-selector.md`
  - Verify: shows active workspace name · dropdown lists all workspaces · `+` creates new · selection updates `AppState.selectedWorkspace`

- [ ] `OutlineGroup` request tree
  - Checklist: `docs/checklists/05-outline-tree.md`
  - Verify: arbitrary depth renders · expand/collapse works · active request highlighted · selection updates `AppState.selectedRequest`

- [ ] `MethodBadge` component
  - Checklist: `docs/checklists/05-method-badge.md`
  - Verify: all 7 methods render · colors match `AppColors.method*` exactly · no hardcoded hex · single `method:` parameter

- [ ] Context menu
  - Checklist: `docs/checklists/05-context-menu.md`
  - Verify: rename/duplicate/delete/move on request rows · rename/delete/new inside on folder rows · actions mutate `AppState`

---

## Phase 6 — Request editor
> Build URL bar + Send first. Then tab panels one at a time.

- [ ] URL bar
  - Checklist: `docs/checklists/06-url-bar.md`
  - Verify: method picker reflects current method · Send triggers `HTTPClient.send` async · loading spinner during request · response stored in `AppState.pendingResponse`

- [ ] `TabBarView` custom segment control
  - Checklist: `docs/checklists/06-tab-bar.md`
  - Verify: NOT `TabView` · Params/Headers/Body/Auth tabs · active tab underline in `AppColors.brand` · content swaps correctly

- [ ] `KVEditor`
  - Checklist: `docs/checklists/06-kv-editor.md`
  - Verify: toggle enables/disables · key and value editable inline · add appends blank enabled row · delete removes · shared by Params + Headers without duplication

- [ ] Body editor
  - Checklist: `docs/checklists/06-body-editor.md`
  - Verify: none/raw/form-data/urlEncoded modes · raw uses `AppFonts.mono` · form-data reuses `KVEditor` · urlEncoded encodes as `key=value&key=value`

- [ ] Auth editor
  - Checklist: `docs/checklists/06-auth-editor.md`
  - Verify: 4 modes · bearer auto-injects `Authorization: Bearer <token>` · injected header does NOT appear in UI headers list

- [ ] Variable highlighting in URL field
  - Checklist: `docs/checklists/06-variable-highlighting.md`
  - Verify: `{{var}}` in `#C96A2A` · non-var text in default color · updates live as user types · no crash on partial `{{` input

---

## Phase 7 — Response viewer
> Stats bar + raw first. JSON tree is the complex part.

- [ ] Stats bar
  - Checklist: `docs/checklists/07-stats-bar.md`
  - Verify: 2xx green · 3xx amber · 4xx/5xx red · ms rounded to integer · KB = `sizeBytes / 1000` to 1 decimal

- [ ] Response `TabBarView`
  - Checklist: `docs/checklists/07-response-tabs.md`
  - Verify: reuses same `TabBarView` from phase 6 · Body/Headers/Cookies/Raw/Preview present

- [ ] `JSONTreeView` recursive viewer
  - Checklist: `docs/checklists/07-json-tree.md`
  - Verify: objects + arrays expand/collapse · syntax colors match `design-system.md` JSON colors · click copies value · 5+ nesting levels do not crash

- [ ] Response headers list
  - Checklist: `docs/checklists/07-response-headers.md`
  - Verify: all headers shown · click copies value · read-only, no edit affordance

- [ ] Raw body view
  - Checklist: `docs/checklists/07-raw-body.md`
  - Verify: `AppFonts.mono` · text selectable · copy-all works · non-UTF8 shows hex fallback, does not crash

---

## Phase 8 — Environments
> Requires phase 3 + phase 6 complete.

- [ ] `EnvEditorSheet`
  - Checklist: `docs/checklists/08-env-editor.md`
  - Verify: opens as `.sheet` · toggle/key/value per var · save persists via `StorageService` · cancel discards · add/delete work

- [ ] `EnvSelectorMenu`
  - Checklist: `docs/checklists/08-env-selector.md`
  - Verify: lists all envs · "No environment" at top · selection updates `AppState.activeEnvironment` · active name shown in toolbar

- [ ] Postman environment import
  - Checklist: `docs/checklists/08-postman-import.md`
  - Verify: `NSOpenPanel` filters to `.json` · decodes Postman format · invalid file shows error alert · imported env appears immediately

- [ ] Variable tooltip in URL bar
  - Checklist: `docs/checklists/08-variable-tooltip.md`
  - Verify: hover shows `.help()` with resolved value · unknown var shows `"(not set)"` · no tooltip when no active environment

---

## Phase 9 — Polish & DX
> Only after phases 0–8 are stable and manually tested end-to-end.

- [ ] History panel
  - Checklist: `docs/checklists/09-history-panel.md`
  - Verify: last 100 entries · grouped by date · click reloads request · method badge + status code visible per row

- [ ] All keyboard shortcuts wired
  - Checklist: `docs/checklists/09-keyboard-shortcuts.md`
  - Verify: `⌘↵` sends · `⌘N` new request · `⌘⇧N` new folder · `⌘K` clear · `⌘E` env editor · `⌘D` duplicate · no system conflicts

- [ ] Drag-and-drop sidebar
  - Checklist: `docs/checklists/09-drag-drop.md`
  - Verify: rows draggable · reorder within folder · move across folders · drop target highlighted · order persists after restart

- [ ] Empty states
  - Checklist: `docs/checklists/09-empty-states.md`
  - Verify: no collections → placeholder · no request selected → placeholder · no response → placeholder · all use `AppColors` + `AppFonts`

- [ ] Error states
  - Checklist: `docs/checklists/09-error-states.md`
  - Verify: network error → message not crash · SSL error → specific message · timeout → message + retry · non-UTF8 body → hex fallback

- [ ] App icon
  - Checklist: `docs/checklists/09-app-icon.md`
  - Verify: all sizes in `Assets.xcassets` · no missing size warnings · uses brand color `#D4622E`

---

## Quick reference

### Storage layout

```
~/.doksli/
└── v1/
    ├── VERSION
    ├── workspaces.json
    ├── environments.json
    └── history.json
```

### Postman environment import format

```json
{
  "name": "Production",
  "values": [
    { "key": "base_url", "value": "https://api.example.com", "enabled": true },
    { "key": "token", "value": "abc123", "enabled": true }
  ]
}
```

### Keyboard shortcuts

| Action | Shortcut |
|---|---|
| Send request | `⌘↵` |
| New request | `⌘N` |
| New folder | `⌘⇧N` |
| Clear response | `⌘K` |
| Open env editor | `⌘E` |
| Duplicate request | `⌘D` |
