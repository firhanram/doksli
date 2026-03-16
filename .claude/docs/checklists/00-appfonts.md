# Verification checklist — AppFonts.swift

## Inputs & outputs
- [ ] File is at `doksli/Resources/AppFonts.swift`
- [ ] Declares `enum AppFonts` with only `static let` / `static let` constants
- [ ] All 5 font role constants are `Font` type: `display`, `title`, `body`, `mono`, `eyebrow`
- [ ] `eyebrowTracking` is `CGFloat` type (not `Font`)

## Happy path
- [ ] `AppFonts.display` is `Font.system(size: 22, weight: .medium)` — 22pt medium
- [ ] `AppFonts.title` is `Font.system(size: 15, weight: .medium)` — 15pt medium
- [ ] `AppFonts.body` is `Font.system(size: 13, weight: .regular)` — 13pt regular
- [ ] `AppFonts.mono` is `Font.system(size: 12, weight: .regular, design: .monospaced)` — 12pt SF Mono
- [ ] `AppFonts.eyebrow` is `Font.system(size: 10, weight: .medium)` — 10pt medium
- [ ] `AppFonts.eyebrowTracking` is `CGFloat` equal to `1.0`

## Edge cases
- [ ] `AppFonts.mono` uses `design: .monospaced` — NOT `design: .default` (must be monospace for code/URLs)
- [ ] No `UIFont` or `NSFont` used anywhere — SwiftUI `Font` only
- [ ] Sizes match `design-system.md` exactly: 22, 15, 13, 12, 10 — not approximations

## Failure cases
- [ ] `AppFonts.body` is NOT named `bodyText` or `bodyFont` — exact name is `body`
- [ ] `AppFonts.mono` is NOT named `monospace` or `code` — exact name is `mono`

## Constraints from CLAUDE.md
- [ ] `import SwiftUI` — `Font` is from SwiftUI
- [ ] No `UIFont` / `NSFont` — hard rule from CLAUDE.md
- [ ] All 5 font roles present — no missing role
- [ ] `eyebrowTracking: CGFloat = 1.0` present as a companion constant

## Does NOT do (out of scope)
- [ ] Does not apply `.textCase(.uppercase)` — that is applied in Views, not in the constant
- [ ] Does not apply `.tracking()` to the `Font` — Views use `eyebrowTracking` constant directly
- [ ] Does not define custom `NSFont` descriptors or font fallbacks
- [ ] Does not define line height or paragraph spacing — those are view-layer concerns

## Integration
- [ ] `URLBarView` (Phase 6) uses `AppFonts.mono` for the URL text field
- [ ] `RawBodyView` (Phase 7) uses `AppFonts.mono` for response body display
- [ ] `JSONTreeView` (Phase 7) uses `AppFonts.mono` for key/value labels
- [ ] Sidebar section headers use `AppFonts.eyebrow` with `.tracking(AppFonts.eyebrowTracking)` and `.textCase(.uppercase)`
