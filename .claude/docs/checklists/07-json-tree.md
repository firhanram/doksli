# Verification checklist — JSONTreeView + JSONNode

## Inputs & outputs
- [ ] `JSONTreeView` input: `let data: Data`
- [ ] `JSONNode` input: `key: String?`, `value: Any`, `depth: Int`
- [ ] Parses JSON via `JSONSerialization` (Foundation native)

## Happy path
- [ ] `{"name": "John"}` → shows key "name" in `AppColors.jsonKey`, value "John" in `AppColors.jsonString`
- [ ] `{"count": 42}` → number value in `AppColors.jsonNumber`
- [ ] `{"active": true}` → boolean value in `AppColors.jsonBoolean`
- [ ] `{"data": null}` → null value in `AppColors.jsonNull`
- [ ] Nested object `{"user": {"name": "John"}}` → expand/collapse works at each level

## Edge cases
- [ ] 5+ nesting levels → renders without crash
- [ ] Empty object `{}` → shows `{ 0 keys }` collapsed
- [ ] Empty array `[]` → shows `[ 0 items ]` collapsed
- [ ] Non-JSON data → falls back to `RawBodyView`
- [ ] Array root `[1, 2, 3]` → renders correctly (not just objects)

## Failure cases
- [ ] Invalid JSON data → graceful fallback to raw view, no crash
- [ ] Empty data → fallback view shown

## Constraints from CLAUDE.md
- [ ] No hardcoded hex colors — uses `AppColors.json*` tokens
- [ ] No hardcoded spacing — uses `AppSpacing` constants
- [ ] No third-party imports
- [ ] Uses `AppFonts.mono` for all text

## Does NOT do (out of scope)
- [ ] Does not edit JSON — read-only viewer
- [ ] Does not search/filter JSON content
- [ ] Does not syntax-highlight raw JSON strings

## Integration
- [ ] `JSONTreeView` used by `ResponseView` body tab when content-type is JSON
- [ ] `JSONNode` is internal — only called by `JSONTreeView` and recursively by itself
- [ ] Click value copies to clipboard via `NSPasteboard`
