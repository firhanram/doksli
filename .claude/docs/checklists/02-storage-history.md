# Verification checklist — StorageService history ring buffer

## Inputs & outputs
- [ ] `loadHistory() -> [HistoryEntry]` — returns array newest-first (empty on failure)
- [ ] `appendHistory(_ entry: HistoryEntry) throws` — prepends entry, enforces 100-entry cap
- [ ] Both are `static` methods on `StorageService`

## Happy path
- [ ] `appendHistory(entry)` then `loadHistory()` returns `[entry]` as first element
- [ ] Appending 3 entries A, B, C → `loadHistory()` returns `[C, B, A]` (newest-first)
- [ ] After 100 entries, appending entry 101 → array remains 100 entries, oldest dropped
- [ ] After 100 entries, entry 101 is at index 0 (newest), original entry 1 is gone

## Edge cases
- [ ] `loadHistory()` when file does not exist → returns `[]`, does not crash
- [ ] `loadHistory()` when file contains corrupt JSON → returns `[]`, does not crash
- [ ] `appendHistory` on a fresh install (no existing history file) → creates file with 1 entry

## Failure cases
- [ ] Ring buffer cap is exactly 100 — NOT 99 or 101
- [ ] `appendHistory` uses same atomic write pattern (temp + rename)
- [ ] If encoding fails → throws, does NOT write partial data

## Constraints from CLAUDE.md
- [ ] No third-party imports — Foundation only
- [ ] Atomic write: temp file then rename
- [ ] File path is `~/.doksli/v1/history.json`
- [ ] Cap is 100 — defined as a named constant or literal, NOT configurable via parameter

## Does NOT do (out of scope)
- [ ] Does not expose a `saveHistory` function replacing the whole array — only `appendHistory`
- [ ] Does not group entries by date — that is a View concern
- [ ] Does not trim entries by date — only by count

## Integration
- [ ] `HistoryEntry` is `Codable` (Phase 1) and round-trips through JSON
- [ ] `HistoryEntry.timestamp` encodes as ISO8601 string (default `JSONEncoder` behavior for `Date`)
