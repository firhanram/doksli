# Agent workflow

Every task follows this protocol — no exceptions.
The checklist comes first. Code comes second.

---

## The golden rule

> An agent that cannot write the verification checklist
> does not understand the task well enough to build it yet.

Read the spec. Read the architecture. Read the design system.
Only then write the checklist. Only then write code.

---

## Step-by-step protocol

```
1. UNDERSTAND   Read the task + all referenced docs
2. PLAN         Write the verification checklist (before any code)
3. REVIEW       Second agent reviews the checklist — is it complete?
4. BUILD        First agent implements
5. SELF-CHECK   First agent runs own checklist — honest pass/fail per item
6. VERIFY       Second agent independently runs the checklist
7. VERDICT      APPROVED or NEEDS CHANGES (with line-level reasons)
8. DONE         Task marked ✅ only after APPROVED
```

Steps 3 and 6 must be done by a different agent than the one who did step 2 and 4.
If only one agent session is running, it must complete step 4, then start a fresh
context window before doing steps 5–7 — no relying on memory of what was just written.

---

## Step 1 — Understand

Before writing a single line, the Builder reads:

- The task description in `todos.md`
- The relevant section in `architecture.md` (data model signatures, service contracts)
- The relevant section in `design-system.md` (if the task touches UI)
- The relevant section in `file-structure.md` (what the file owns, what it must not own)
- Any existing code that the new code will call or be called by

The Builder cannot proceed to step 2 until it can answer:
- What exact inputs does this take?
- What exact outputs does it produce?
- What are the failure cases?
- What does this depend on?
- What depends on this?

---

## Step 2 — Write the verification checklist

The Builder writes the checklist as a markdown file at:

```
docs/checklists/<phase>-<task-slug>.md
```

Example: `docs/checklists/03-variable-resolver.md`

### Checklist format

```markdown
# Verification checklist — <task name>

## Inputs & outputs
- [ ] Input type matches spec: <exact type from architecture.md>
- [ ] Output type matches spec: <exact type from architecture.md>
- [ ] Function signature matches: <paste exact signature>

## Happy path
- [ ] <specific input> → <specific expected output>
- [ ] <specific input> → <specific expected output>
- (minimum 2 concrete examples with real values)

## Edge cases
- [ ] Empty input → <expected behaviour>
- [ ] Nil / missing value → <expected behaviour>
- [ ] Invalid input → <expected behaviour>

## Failure cases
- [ ] <error condition> → throws / returns nil / logs (pick one, be specific)
- [ ] <error condition> → does NOT silently swallow the error

## Constraints from CLAUDE.md
- [ ] No third-party imports
- [ ] No hardcoded colors (if UI task)
- [ ] No hardcoded spacing (if UI task)
- [ ] Atomic file write (if storage task)
- [ ] Returns copy, never mutates input (if resolver task)

## Does NOT do (out of scope)
- [ ] Confirm: this file does not contain <out-of-scope concern>
- [ ] Confirm: this file does not contain <out-of-scope concern>

## Integration
- [ ] Called correctly by <caller file>
- [ ] Dependency <dependency file> exists and compiles before this runs
```

The checklist must have a minimum of:
- 2 happy path cases with concrete real values (not "input X → output Y")
- 2 edge cases
- 1 failure / error case
- All applicable constraints from `CLAUDE.md`

---

## Step 3 — Checklist review

The Reviewer reads the checklist and answers:

1. Is every item specific enough to be unambiguously pass/fail?
2. Are the happy path examples using real concrete values?
3. Are the edge cases actually the risky ones for this task?
4. Does the "does NOT do" section accurately describe the boundary?
5. Are all hard rules from `CLAUDE.md` represented?

The Reviewer either:
- **Approves the checklist** → Builder may proceed to step 4
- **Returns with comments** → Builder revises before any code is written

A vague checklist item like "works correctly" or "handles errors" is an automatic return.
Every item must be falsifiable — you must be able to clearly fail it.

---

## Step 4 — Build

Builder implements. References the checklist continuously, not just at the end.

If during implementation the Builder discovers the checklist was wrong or incomplete,
it stops, updates the checklist, and gets Reviewer sign-off again before continuing.

---

## Step 5 — Self-check

Builder runs through every checklist item honestly.

For each item, write one of:
- `PASS` — with one sentence of evidence
- `FAIL` — with the exact reason
- `PARTIAL` — with what is and isn't working

Do not submit to Reviewer with any `FAIL` items.
`PARTIAL` items must be explained and justified.

---

## Step 6 — Verify

Reviewer independently runs the checklist. Does not read the Builder's self-check first —
forms its own verdict, then compares.

The Reviewer:
- Actually runs the code / reads the implementation
- Does not take the Builder's word for anything
- Checks the file does NOT contain the out-of-scope items
- Checks integration points compile and connect correctly

---

## Step 7 — Verdict

### APPROVED

```
VERDICT: APPROVED
Reviewer: <agent id or session>
Date: <date>
All checklist items: PASS
Notes: <optional observations that don't block approval>
```

Task is marked `✅` in `todos.md`.

### NEEDS CHANGES

```
VERDICT: NEEDS CHANGES
Reviewer: <agent id or session>
Date: <date>

Failed items:
- [ ] <checklist item> — <specific reason it failed>
- [ ] <checklist item> — <specific reason it failed>

Required before re-review:
1. <concrete change needed>
2. <concrete change needed>
```

Builder fixes, re-runs self-check, resubmits.
Reviewer only re-checks the previously failed items unless the fix introduces new surface area.

---

## Checklist file naming

```
docs/checklists/
├── 00-xcode-setup.md
├── 00-appcolors.md
├── 01-workspace-model.md
├── 01-request-model.md
├── 02-storage-workspaces.md
├── 02-storage-history.md
├── 03-variable-resolver.md
├── 03-http-client-build.md
├── 03-http-client-send.md
├── 04-app-state.md
├── 04-navigation-shell.md
├── 05-sidebar-tree.md
├── 05-method-badge.md
├── 06-url-bar.md
├── 06-kv-editor.md
├── 06-body-editor.md
├── 07-json-tree-view.md
├── 07-stats-bar.md
├── 08-env-editor.md
├── 08-postman-import.md
└── 09-history-panel.md
```

Each checklist file lives permanently in the repo as a record of what was verified.

---

## Status tracking

Update `todos.md` task status using these markers:

| Marker | Meaning |
|---|---|
| `[ ]` | Not started |
| `[~]` | Checklist written, awaiting checklist review |
| `[b]` | Building — checklist approved, code in progress |
| `[s]` | Self-check complete, awaiting Reviewer |
| `[x]` | ✅ APPROVED — done |
| `[!]` | ❌ NEEDS CHANGES — returned by Reviewer |

Example in todos.md:
```markdown
- [x] ✅ `VariableResolver.resolve()` — approved 2024-01-15
- [b] 🔨 `HTTPClient.buildRequest()` — building
- [~] 📋 `StorageService.save()` — checklist under review
- [ ]  `AppState` — not started
```

---

## Example checklist — VariableResolver

`docs/checklists/03-variable-resolver.md`

```markdown
# Verification checklist — VariableResolver.resolve()

## Inputs & outputs
- [ ] Input: `string: String`, `environment: Environment?` — matches architecture.md
- [ ] Output: `String` — resolved copy, same type as input
- [ ] Signature: `func resolve(_ string: String, environment: Environment?) -> String`

## Happy path
- [ ] `resolve("Bearer {{token}}", env where token="sk_live_abc")` → `"Bearer sk_live_abc"`
- [ ] `resolve("https://{{base_url}}/v1/users", env where base_url="api.example.com")` → `"https://api.example.com/v1/users"`
- [ ] Multiple vars in one string: `resolve("{{scheme}}://{{host}}", env)` → all replaced in one pass

## Edge cases
- [ ] Unknown var: `resolve("Bearer {{unknown}}", env)` → `"Bearer {{unknown}}"` — left as-is
- [ ] Disabled var: `resolve("{{token}}", env where token disabled)` → `"{{token}}"` — not substituted
- [ ] Nil environment: `resolve("{{token}}", nil)` → `"{{token}}"` — no crash, returned as-is
- [ ] Empty string: `resolve("", env)` → `""` — no crash
- [ ] No vars in string: `resolve("https://api.example.com", env)` → `"https://api.example.com"` — unchanged

## Failure cases
- [ ] Malformed pattern `{{}}` → left as-is, no crash
- [ ] Does NOT throw — returns string in all cases

## Constraints from CLAUDE.md
- [ ] No third-party imports — Foundation only
- [ ] Returns a copy — original `string` parameter is not mutated
- [ ] No UI imports — this is a pure Swift service

## Does NOT do (out of scope)
- [ ] Does not validate whether URLs are valid after substitution
- [ ] Does not substitute into header keys — only values
- [ ] Does not log or print substituted values (security)

## Integration
- [ ] Called by `HTTPClient.buildRequest(from:environment:)` before URLRequest is built
- [ ] `Environment` model exists and compiles before this file
```
