# Verification checklist — Variable tooltip in URL bar

## Inputs & outputs
- [ ] `VariableResolver.tooltipText(for:environment:)` → `String?`
- [ ] Scans string for `{{var}}` tokens, resolves against environment
- [ ] Applied as `.help()` on URL `TextField`

## Happy path
- [ ] URL `{{base_url}}/users` with env where `base_url=https://api.com` → tooltip: `{{base_url}} = https://api.com`
- [ ] Multiple vars `{{scheme}}://{{host}}` → multiline tooltip with both resolved

## Edge cases
- [ ] Unknown var `{{unknown}}` → tooltip shows `{{unknown}} = (not set)`
- [ ] No active environment → no tooltip (returns nil → empty string)
- [ ] No `{{var}}` tokens in URL → no tooltip
- [ ] Duplicate var `{{x}}/{{x}}` → shown only once in tooltip
- [ ] Disabled var → shown as `(not set)`

## Failure cases
- [ ] Empty string → returns nil, no crash
- [ ] Malformed `{{` without closing → no match, no tooltip

## Constraints from CLAUDE.md
- [ ] Logic in `VariableResolver` service, not in the view
- [ ] No third-party imports

## Does NOT do (out of scope)
- [ ] Does not highlight individual `{{var}}` tokens with color (Phase 6 todo)
- [ ] Does not show per-character tooltips — whole-field tooltip only

## Integration
- [ ] `.help()` modifier on URL `TextField` in `URLBarView`
- [ ] Uses `VariableResolver.tooltipText(for:environment:)`
