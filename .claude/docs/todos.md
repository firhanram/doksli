# Development todos

Work top to bottom. Never skip a phase — each one is a dependency of the next.

**Before touching any task, read `docs/agent-workflow.md`.**
Every task requires a verification checklist written and approved before code starts.

## Status markers

| Marker | Meaning |
|---|---|
| `[ ]` | Not started |
| `[b]` | Checklist written, awaiting checklist review |
| `[b]` | Building — checklist approved, code in progress |
| `[s]` | Self-check done, awaiting Reviewer |
| `[x]` | ✅ APPROVED — done |
| `[!]` | ❌ NEEDS CHANGES — returned by Reviewer |

---

## Phase 0 — Project setup
> Must be done before writing any Swift code.

- [x] ✅ Create macOS app target in Xcode — approved 2026-03-16
  - Checklist: `docs/checklists/00-xcode-setup.md`
  - Verify: SwiftUI lifecycle · macOS 13+ · bundle ID `com.yourname.doksli` · sandbox entitlement for outgoing connections

- [x] ✅ Create storage directory scheme — approved 2026-03-16
  - Checklist: `docs/checklists/00-storage-scheme.md`
  - Verify: `~/.doksli/v1/` exists on first launch · `VERSION` file written · directory not inside app bundle

- [x] ✅ Set up folder structure — approved 2026-03-16
  - Checklist: `docs/checklists/00-folder-structure.md`
  - Verify: matches `file-structure.md` exactly · no extra files · no missing groups in Xcode

- [x] ✅ `AppColors.swift` — approved 2026-03-16
  - Checklist: `docs/checklists/00-appcolors.md`
  - Verify: every token from `design-system.md` is present · no hardcoded hex anywhere else · compiles clean

- [x] ✅ `AppFonts.swift` — approved 2026-03-16
  - Checklist: `docs/checklists/00-appfonts.md`
  - Verify: all 5 font roles present · SF Mono for mono role · no `UIFont` / `NSFont` used directly in views

- [x] ✅ `AppSpacing.swift` — approved 2026-03-16
  - Checklist: `docs/checklists/00-appspacing.md`
  - Verify: all 7 spacing values + 5 radius values present · all typed as `CGFloat` · no magic numbers in views

---

## Phase 1 — Data models
> Define all `Codable` structs before writing a single View.

- [x] ✅ `Workspace` model — approved 2026-03-16
  - Checklist: `docs/checklists/01-workspace-model.md`
  - Verify: `Codable` · `Identifiable` · all fields match `architecture.md` · encode→decode round-trip passes

- [x] ✅ `Collection` + `Folder` + recursive `Item` enum — approved 2026-03-16
  - Checklist: `docs/checklists/01-collection-model.md`
  - Verify: `Item` enum has exactly `.folder(Folder)` and `.request(Request)` · arbitrary depth encodes correctly · no infinite loop risk

- [x] ✅ `Request` + `KVPair` + `HTTPMethod` + `RequestBody` + `Auth` — approved 2026-03-16
  - Checklist: `docs/checklists/01-request-model.md`
  - Verify: all associated enums are `Codable` · `RequestBody` covers all 4 cases · `Auth` covers all 4 cases

- [x] ✅ `Response` model — approved 2026-03-16
  - Checklist: `docs/checklists/01-response-model.md`
  - Verify: `Codable` (needed for history) · `body: Data` encodes as base64 · all fields present

- [x] ✅ `Environment` + `EnvVar` — approved 2026-03-16
  - Checklist: `docs/checklists/01-environment-model.md`
  - Verify: `Codable` · `enabled: Bool` present on `EnvVar` · encode→decode round-trip passes

- [x] ✅ `HistoryEntry` — approved 2026-03-16
  - Checklist: `docs/checklists/01-history-entry-model.md`
  - Verify: `Codable` · snapshot — not a reference to live `Request` · `timestamp: Date` encodes as ISO8601

---

## Phase 2 — Storage service
> Write and verify persistence before any UI.

- [x] ✅ `StorageService` — workspaces read/write — approved 2026-03-17
  - Checklist: `docs/checklists/02-storage-workspaces.md`
  - Verify: atomic write (temp + rename) · file created on first save · loads correctly after restart simulation · corrupt file returns empty, does not crash

- [x] ✅ `StorageService` — environments read/write — approved 2026-03-17
  - Checklist: `docs/checklists/02-storage-environments.md`
  - Verify: separate file from workspaces · same atomic write pattern · empty environments returns `[]`

- [x] ✅ `StorageService` — history ring buffer — approved 2026-03-17
  - Checklist: `docs/checklists/02-storage-history.md`
  - Verify: capped at 100 · 101st entry drops oldest · order is newest-first · empty returns `[]`

- [x] ✅ `XCTest` round-trip suite — approved 2026-03-17
  - Checklist: `docs/checklists/02-storage-tests.md`
  - Verify: Workspace round-trip · Request with all body types round-trip · Response with binary body round-trip

---

## Phase 3 — HTTP client & variable resolver
> Pure Swift. No SwiftUI dependency. Test in isolation.

- [x] ✅ `VariableResolver.resolve()` — approved 2026-03-17
  - Checklist: `docs/checklists/03-variable-resolver.md`
  - Verify: known vars replaced · unknown vars left as-is · disabled vars skipped · nil env safe · original string not mutated
  - See example checklist in `agent-workflow.md`

- [x] ✅ `HTTPClient.buildRequest(from:environment:)` — approved 2026-03-17
  - Checklist: `docs/checklists/03-http-client-build.md`
  - Verify: all 7 methods produce correct `httpMethod` · query params appended · headers set · body encoded per `RequestBody` · vars resolved before building

- [x] ✅ `HTTPClient.send(_:)` — approved 2026-03-17
  - Checklist: `docs/checklists/03-http-client-send.md`
  - Verify: `async throws` · `ContinuousClock` wraps session call · network error propagates · cancellation handled

- [x] ✅ Response mapping `HTTPURLResponse` → `Response` — approved 2026-03-17
  - Checklist: `docs/checklists/03-response-mapping.md`
  - Verify: status code extracted · all headers captured as `[KVPair]` · `sizeBytes` = `data.count` · `durationMs` is wall-clock time

- [x] ✅ Integration tests against `httpbin.org` — approved 2026-03-17
  - Checklist: `docs/checklists/03-integration-tests.md`
  - Verify: `GET /get` returns 200 · `POST /post` with JSON body echoes body · headers round-trip · `DELETE /delete` returns 200

---

## Phase 4 — App shell & navigation
> Build skeleton with placeholder content before filling in real views.

- [x] ✅ `NavigationSplitView` shell — approved 2026-03-17
  - Checklist: `docs/checklists/04-navigation-shell.md`
  - Verify: 3 columns present · sidebar 200px min · content flexible · window min size `900×600` · columns collapse correctly

- [x] ✅ `AppState` observable object — approved 2026-03-17
  - Checklist: `docs/checklists/04-app-state.md`
  - Verify: all 6 published properties present · `@MainActor` annotation · injected via `@StateObject` at root · no business logic inside `AppState`

- [x] ✅ Toolbar — approved 2026-03-17
  - Checklist: `docs/checklists/04-toolbar.md`
  - Verify: env selector `Menu` on right · keyboard shortcuts defined · `.preferredColorScheme(.light)` at `WindowGroup`

---

## Phase 5 — Sidebar
> Build before request editor — needed to load and switch requests.

- [x] ✅ Workspace selector — approved 2026-03-17
  - Checklist: `docs/checklists/05-workspace-selector.md`
  - Verify: shows active workspace name · dropdown lists all workspaces · `+` creates new · selection updates `AppState.selectedWorkspace`

- [x] ✅ `OutlineGroup` request tree — approved 2026-03-17
  - Checklist: `docs/checklists/05-outline-tree.md`
  - Verify: arbitrary depth renders · expand/collapse works · active request highlighted · selection updates `AppState.selectedRequest`

- [x] ✅ `MethodBadge` component — approved 2026-03-17
  - Checklist: `docs/checklists/05-method-badge.md`
  - Verify: all 7 methods render · colors match `AppColors.method*` exactly · no hardcoded hex · single `method:` parameter

- [x] ✅ Context menu — approved 2026-03-17
  - Checklist: `docs/checklists/05-context-menu.md`
  - Verify: rename/duplicate/delete/move on request rows · rename/delete/new inside on folder rows · actions mutate `AppState`

---

## Phase 6 — Request editor
> Build URL bar + Send first. Then tab panels one at a time.

- [x] ✅ URL bar — approved 2026-03-17
  - Checklist: `docs/checklists/06-url-bar.md`
  - Verify: method picker reflects current method · Send triggers `HTTPClient.send` async · loading spinner during request · response stored in `AppState.pendingResponse`

- [x] ✅ `TabBarView` custom segment control — approved 2026-03-17
  - Checklist: `docs/checklists/06-tab-bar.md`
  - Verify: NOT `TabView` · Params/Headers/Body/Auth tabs · active tab underline in `AppColors.brand` · content swaps correctly

- [x] ✅ `KVEditor` — approved 2026-03-17
  - Checklist: `docs/checklists/06-kv-editor.md`
  - Verify: toggle enables/disables · key and value editable inline · add appends blank enabled row · delete removes · shared by Params + Headers without duplication

- [x] ✅ Body editor — approved 2026-03-17
  - Checklist: `docs/checklists/06-body-editor.md`
  - Verify: none/raw/form-data/urlEncoded modes · raw uses `AppFonts.mono` · form-data reuses `KVEditor` · urlEncoded encodes as `key=value&key=value`

- [x] ✅ Auth editor — approved 2026-03-17
  - Checklist: `docs/checklists/06-auth-editor.md`
  - Verify: 4 modes · bearer auto-injects `Authorization: Bearer <token>` · injected header does NOT appear in UI headers list

- [ ] Variable highlighting in URL field
  - Checklist: `docs/checklists/06-variable-highlighting.md`
  - Verify: `{{var}}` in `#C96A2A` · non-var text in default color · updates live as user types · no crash on partial `{{` input

- [s] Raw body editor — SwiftUI TextEditor + JSONValidator
  - Checklist: `docs/checklists/06-json-editor.md`
  - Verify: TextEditor with mono font · validation indicator green/red · format button formats valid JSON · format disabled when invalid · error banner below editor · debounce 300ms

---

## Phase 7 — Response viewer
> Stats bar + raw first. JSON tree is the complex part.

- [s] Stats bar
  - Checklist: `docs/checklists/07-stats-bar.md`
  - Verify: 2xx green · 3xx amber · 4xx/5xx red · ms rounded to integer · KB = `sizeBytes / 1000` to 1 decimal

- [s] Response `TabBarView`
  - Checklist: `docs/checklists/07-response-tabs.md`
  - Verify: reuses same `TabBarView` from phase 6 · Body/Headers/Raw present

- [s] `JSONTreeView` recursive viewer
  - Checklist: `docs/checklists/07-json-tree.md`
  - Verify: objects + arrays expand/collapse · syntax colors match `design-system.md` JSON colors · click copies value · 5+ nesting levels do not crash

- [s] Response headers list
  - Checklist: `docs/checklists/07-response-headers.md`
  - Verify: all headers shown · click copies value · read-only, no edit affordance

- [s] Raw body view
  - Checklist: `docs/checklists/07-raw-body.md`
  - Verify: `AppFonts.mono` · text selectable · copy-all works · non-UTF8 shows hex fallback, does not crash

---

## Phase 8 — Environments
> Requires phase 3 + phase 6 complete.

- [s] `EnvEditorSheet`
  - Checklist: `docs/checklists/08-env-editor.md`
  - Verify: opens as `.sheet` · toggle/key/value per var · save persists via `StorageService` · cancel discards · add/delete work

- [s] `EnvSelectorMenu`
  - Checklist: `docs/checklists/08-env-selector.md`
  - Verify: lists all envs · "No environment" at top · selection updates `AppState.activeEnvironment` · active name shown in toolbar

- [s] Postman environment import
  - Checklist: `docs/checklists/08-postman-import.md`
  - Verify: `NSOpenPanel` filters to `.json` · decodes Postman format · invalid file shows error alert · imported env appears immediately

- [s] Variable tooltip in URL bar
  - Checklist: `docs/checklists/08-variable-tooltip.md`
  - Verify: hover shows `.help()` with resolved value · unknown var shows `"(not set)"` · no tooltip when no active environment

---

## Phase 9 — Polish & DX
> Only after phases 0–8 are stable and manually tested end-to-end.

- [s] Error states
  - Checklist: `docs/checklists/09-error-states.md`
  - Verify: network error → message not crash · SSL error → specific message · timeout → message + retry · non-UTF8 body → hex fallback

- [s] All keyboard shortcuts wired
  - Checklist: `docs/checklists/09-keyboard-shortcuts.md`
  - Verify: `⌘↵` sends · `⌘N` new request · `⌘⇧N` new folder · `⌘K` clear · `⌘E` env editor · `⌘D` duplicate · no system conflicts

- [s] History panel
  - Checklist: `docs/checklists/09-history-panel.md`
  - Verify: last 100 entries · grouped by date · click reloads request · method badge + status code visible per row

- [s] Empty states
  - Checklist: `docs/checklists/09-empty-states.md`
  - Verify: no collections → placeholder · no request selected → placeholder · no response → placeholder · all use `AppColors` + `AppFonts`

- [s] Drag-and-drop sidebar
  - Checklist: `docs/checklists/09-drag-drop.md`
  - Verify: rows draggable · move across folders · drop into folder expands it · order persists after restart

- [ ] App icon — deferred (requires external design tooling)
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
