# Verification checklist — Error States

## Inputs & outputs
- [ ] `AppState.lastError` is `String?` — set on failure, nil on success or clear
- [ ] `AppState.sendCurrentRequest()` maps errors to user-friendly messages
- [ ] `ResponseView` shows error state when `lastError` is non-nil and `pendingResponse` is nil

## Happy path
- [ ] Send valid request → response appears, `lastError` is nil
- [ ] Send request then send another → previous error clears before new request

## Edge cases
- [ ] Invalid URL (e.g. empty with spaces) → shows "Invalid URL: ..." message
- [ ] Cannot find host → shows "Cannot find host" message
- [ ] Timeout → shows "Request timed out" with retry button
- [ ] SSL error → shows "SSL/TLS connection failed"
- [ ] No internet → shows "No internet connection"
- [ ] Cannot connect to host → shows "Cannot connect to server"
- [ ] Unknown error → shows `error.localizedDescription`

## Error view UI
- [ ] Error icon: `exclamationmark.triangle` SF Symbol
- [ ] Error text uses `AppColors.errorText`
- [ ] Retry button present, styled with `AppColors.brand`
- [ ] Clicking retry re-sends the current request

## State transitions
- [ ] `lastError` cleared at start of every new send (`sendCurrentRequest` sets `lastError = nil`)
- [ ] `lastError` cleared when `clearResponse()` is called (`⌘K`)
- [ ] Loading state takes priority over error state (isLoading → loading view)
- [ ] Response takes priority over error state (pendingResponse → response view)

## Constraints from CLAUDE.md
- [ ] No third-party imports
- [ ] No hardcoded colors — uses `AppColors` tokens only
- [ ] No hardcoded spacing — uses `AppSpacing` constants only
- [ ] Error mapping logic lives in AppState (service layer), not in Views

## Does NOT do (out of scope)
- [ ] Does not retry automatically — manual retry only
- [ ] Does not log errors to file
- [ ] Does not show error toast/banner — uses full response panel area

## Integration
- [ ] `URLBarView.sendRequest()` delegates to `appState.sendCurrentRequest()`
- [ ] `ResponseView` reads `appState.lastError` for error display
- [ ] `ToolbarView` `⌘K` calls `appState.clearResponse()` which clears error
