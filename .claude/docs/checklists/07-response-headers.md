# Verification checklist — HeadersListView

## Inputs & outputs
- [ ] Input: `let headers: [KVPair]` — matches architecture.md
- [ ] Output: `some View` — scrollable read-only list

## Happy path
- [ ] Headers `[("Content-Type", "application/json"), ("X-Request-Id", "abc123")]` → both rows visible
- [ ] Click on header row → copies value to clipboard via `NSPasteboard`

## Edge cases
- [ ] Empty headers `[]` → shows empty scroll view, no crash
- [ ] Long header value → wraps or truncates gracefully
- [ ] Many headers (20+) → scrollable without performance issues

## Failure cases
- [ ] Clipboard write failure → does not crash (NSPasteboard is reliable)

## Constraints from CLAUDE.md
- [ ] No hardcoded hex colors — uses `AppColors` tokens
- [ ] No hardcoded spacing — uses `AppSpacing` constants
- [ ] Uses `AppFonts.mono` for header keys and values
- [ ] No third-party imports

## Does NOT do (out of scope)
- [ ] No edit affordance — strictly read-only
- [ ] No toggle/checkbox — not a KVEditor
- [ ] No add/delete buttons

## Integration
- [ ] Used by `ResponseView` when Headers tab is active
- [ ] Receives `response.headers` from `Response` model
