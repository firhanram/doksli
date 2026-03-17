# Verification checklist — RawBodyView

## Inputs & outputs
- [ ] Input: `let data: Data` — raw response body bytes
- [ ] Output: `some View` — scrollable mono text with copy button

## Happy path
- [ ] UTF-8 text body `"Hello, World!"` → displays as readable text
- [ ] JSON body → displays raw JSON string in mono font
- [ ] Copy button → copies full body text to clipboard

## Edge cases
- [ ] Empty data → shows empty text, no crash
- [ ] Non-UTF8 binary data → shows hex fallback (e.g. "4F 2A 00 FF")
- [ ] Large body (100KB+) → scrollable without crash

## Failure cases
- [ ] Non-UTF8 data → hex representation, does NOT crash

## Constraints from CLAUDE.md
- [ ] No hardcoded hex colors — uses `AppColors` tokens
- [ ] No hardcoded spacing — uses `AppSpacing` constants
- [ ] Uses `AppFonts.mono` for body text
- [ ] Text is selectable via `.textSelection(.enabled)`
- [ ] No third-party imports

## Does NOT do (out of scope)
- [ ] Does not parse or format JSON — shows raw text as-is
- [ ] Does not syntax highlight
- [ ] Does not edit — read-only

## Integration
- [ ] Used by `ResponseView` for Raw tab
- [ ] Also used as fallback by `JSONTreeView` when JSON parsing fails
- [ ] Copy button uses `NSPasteboard.general`
