# Verification checklist — MethodBadge component

## Inputs & outputs
- [ ] Struct signature: `struct MethodBadge: View`
- [ ] File location: `Views/Sidebar/MethodBadge.swift`
- [ ] Single parameter: `method: HTTPMethod`

## Happy path
- [ ] `MethodBadge(method: .GET)` renders "GET" with bg `AppColors.methodGet.bg` and text `AppColors.methodGet.text`
- [ ] `MethodBadge(method: .POST)` renders "POST" with bg `AppColors.methodPost.bg` and text `AppColors.methodPost.text`
- [ ] `MethodBadge(method: .PUT)` renders "PUT" with `AppColors.methodPut` colors
- [ ] `MethodBadge(method: .DELETE)` renders "DEL" with `AppColors.methodDelete` colors
- [ ] `MethodBadge(method: .PATCH)` renders "PATCH" with `AppColors.methodPatch` colors (note: may abbreviate)
- [ ] `MethodBadge(method: .OPTIONS)` renders "OPT" with `AppColors.methodOptions` colors
- [ ] `MethodBadge(method: .HEAD)` renders "HEAD" with `AppColors.methodHead` colors
- [ ] Corner radius is `AppSpacing.radiusBadge` (3pt)

## Edge cases
- [ ] All 7 methods render without crash
- [ ] Badge has consistent width — either fixed or min-width so layout is stable
- [ ] Text uses `AppFonts.eyebrow` font style

## Failure cases
- [ ] No hardcoded hex anywhere in the file — all colors via `AppColors.method*`

## Constraints from CLAUDE.md
- [ ] No third-party imports — SwiftUI only
- [ ] No hardcoded hex colors — reads from `AppColors.method*` MethodColor pairs
- [ ] No hardcoded spacing — uses `AppSpacing` constants
- [ ] Reusable — used in sidebar `RequestRow` and later in history panel

## Does NOT do (out of scope)
- [ ] Does not handle tap actions — it is a display-only component
- [ ] Does not include request name — that is `RequestRow`'s responsibility

## Integration
- [ ] `HTTPMethod` enum from Request.swift
- [ ] `MethodColor` struct from AppColors.swift (has `.bg` and `.text` properties)
- [ ] Used inside `RequestRow` in the sidebar
