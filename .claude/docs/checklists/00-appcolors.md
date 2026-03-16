# Verification checklist — AppColors.swift

## Inputs & outputs
- [ ] File is at `doksli/Resources/AppColors.swift`
- [ ] Declares `enum AppColors` with only `static let` constants — no instance properties
- [ ] Declares `struct MethodColor` with `bg: Color` and `text: Color`
- [ ] `Color(hex:)` initializer is `private extension Color` — usable only within this file

## Happy path
- [ ] All 6 neutral surface tokens present: `canvas`, `surface`, `surfacePlus`, `subtle`, `border`, `muted`
- [ ] All 5 text scale tokens present: `textPrimary`, `textSecondary`, `textTertiary`, `textPlaceholder`, `textFaint`
- [ ] All 5 brand accent tokens present: `brandTint50`, `brandTint100`, `brand`, `brandHover`, `brandPressed`
- [ ] All 4 semantic background tokens present: `successBg`, `infoBg`, `warningBg`, `errorBg`
- [ ] All 4 semantic text tokens present: `successText`, `infoText`, `warningText`, `errorText`
- [ ] All 7 HTTP method colors present as `MethodColor`: `methodGet`, `methodPost`, `methodPut`, `methodDelete`, `methodPatch`, `methodOptions`, `methodHead`
- [ ] All 6 JSON syntax colors present: `jsonKey`, `jsonString`, `jsonNumber`, `jsonBoolean`, `jsonNull`, `jsonPunctuation`
- [ ] `AppColors.brand` resolves to sRGB (0.831, 0.384, 0.180) approximately (hex `#D4622E`)

## Edge cases
- [ ] `Color(hex:)` handles `#` prefix correctly (strips it via `CharacterSet.alphanumerics.inverted`)
- [ ] `Color(hex:)` handles 6-digit uppercase and lowercase hex strings
- [ ] `Color(hex:)` is `private` — calling `Color(hex: "#D4622E")` from any file other than `AppColors.swift` produces a compiler error

## Failure cases
- [ ] Token count: total constant count is 6+5+5+4+4+7+6 = 37 tokens — no missing token
- [ ] No token returns `.clear` or `.black` by default — all initialize from valid hex strings

## Constraints from CLAUDE.md
- [ ] `import SwiftUI` only — `Color` is from SwiftUI
- [ ] No hardcoded hex strings outside this file — `AppColors.*` is the only way other files access colors
- [ ] Hex values match `design-system.md` exactly (no approximations)
- [ ] `private extension Color` — enforces the "no hardcoded hex in views" rule at compile time

## Does NOT do (out of scope)
- [ ] Does not define named colors in `Assets.xcassets` — all colors are code-defined
- [ ] Does not define elevation shadows — those are applied inline in views
- [ ] Does not define any spacing or font constants — those belong in `AppSpacing` and `AppFonts`

## Integration
- [ ] `MethodBadge` (Phase 5) will use `AppColors.method*` to set background and text color
- [ ] `StatsBarView` (Phase 7) will use `AppColors.successBg/Text`, `warningBg/Text`, `errorBg/Text` for status chips
- [ ] `JSONTreeView` (Phase 7) will use `AppColors.json*` for syntax highlighting
