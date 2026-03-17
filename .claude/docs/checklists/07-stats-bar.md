# Verification checklist — StatsBarView

## Inputs & outputs
- [ ] Input: `let response: Response` — matches architecture.md
- [ ] EnvironmentObject: `AppState` for clear action
- [ ] Output: `some View` — HStack with status chip, duration, size, copy, clear

## Happy path
- [ ] 200 response → green chip (`successBg`/`successText`), shows "200"
- [ ] 404 response → red chip (`errorBg`/`errorText`), shows "404"
- [ ] Duration 142.7ms → displays "142 ms" (rounded to integer)
- [ ] Size 2048 bytes → displays "2.0 KB" (sizeBytes / 1000, 1 decimal)

## Edge cases
- [ ] 301 response → amber chip (`warningBg`/`warningText`)
- [ ] 0ms duration → displays "0 ms"
- [ ] Very large response (1MB) → displays "1000.0 KB"

## Failure cases
- [ ] Copy button with non-UTF8 body → does not crash, no-op if decode fails

## Constraints from CLAUDE.md
- [ ] No hardcoded hex colors — uses `AppColors` tokens only
- [ ] No hardcoded spacing — uses `AppSpacing` constants only
- [ ] No third-party imports — SwiftUI + Foundation only
- [ ] Uses `AppFonts.mono` for status/duration/size text

## Does NOT do (out of scope)
- [ ] Does not parse response body — only displays stats
- [ ] Does not contain tab bar or tab content

## Integration
- [ ] Used by `ResponseView` when `pendingResponse` is non-nil
- [ ] Clear button sets `appState.pendingResponse = nil`
- [ ] Copy button copies body text to `NSPasteboard`
