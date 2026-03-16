# Verification checklist — AppSpacing.swift

## Inputs & outputs
- [ ] File is at `doksli/Resources/AppSpacing.swift`
- [ ] Declares `enum AppSpacing` with only `static let` constants
- [ ] All 7 spacing constants are `CGFloat` type
- [ ] All 5 radius constants are `CGFloat` type

## Happy path
- [ ] All 7 spacing values present with correct values: `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `xxl=32`, `xxxl=48`
- [ ] All 5 radius values present with correct values: `radiusBadge=3`, `radiusInput=5`, `radiusCard=7`, `radiusPanel=10`, `radiusPill=20`
- [ ] `AppSpacing.lg` evaluates to `16.0` as `CGFloat`
- [ ] `AppSpacing.radiusCard` evaluates to `7.0` as `CGFloat`

## Edge cases
- [ ] All constants are typed as `CGFloat`, not `Int` or `Double` — ensures no type coercion needed in `.padding()` / `.cornerRadius()` calls
- [ ] Token names match `design-system.md` exactly: `xs`, `sm`, `md`, `lg`, `xl`, `xxl`, `xxxl` — not `small`, `medium`, `large`
- [ ] Radius names match exactly: `radiusBadge`, `radiusInput`, `radiusCard`, `radiusPanel`, `radiusPill`

## Failure cases
- [ ] Total constant count: 7 spacing + 5 radius = 12 constants — no missing constant
- [ ] No constant returns `0` — every constant has a positive non-zero value

## Constraints from CLAUDE.md
- [ ] `import Foundation` only — `CGFloat` is in Foundation on macOS, no `SwiftUI` import needed
- [ ] No hardcoded spacing magic numbers anywhere else in the project — only `AppSpacing.*` constants used in Views
- [ ] No `UIEdgeInsets` or `NSEdgeInsets` — SwiftUI padding uses `CGFloat` directly

## Does NOT do (out of scope)
- [ ] Does not define color or font constants — those belong in `AppColors` and `AppFonts`
- [ ] Does not define layout-specific values like column widths (sidebar min width 200px is defined in the shell View)
- [ ] Does not define animation durations

## Integration
- [ ] All Views (Phases 4–9) use `AppSpacing.lg` for panel padding, `AppSpacing.sm` for component gaps, etc.
- [ ] `MethodBadge` (Phase 5) uses `AppSpacing.radiusBadge` for pill corner radius
- [ ] `KVEditor` rows (Phase 6) use `AppSpacing.md` for row padding
