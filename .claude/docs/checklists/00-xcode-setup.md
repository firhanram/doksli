# Verification checklist — Xcode project setup

## Inputs & outputs
- [ ] Bundle ID in `project.pbxproj` is `com.firhanram.doksli` (both Debug and Release configurations)
- [ ] Deployment target in `project.pbxproj` is `MACOSX_DEPLOYMENT_TARGET = 13.0` (both Debug and Release)
- [ ] `doksli.entitlements` has exactly 3 keys: `com.apple.security.app-sandbox`, `com.apple.security.files.user-selected.read-only`, `com.apple.security.network.client`
- [ ] `doksliApp.swift` has `.preferredColorScheme(.light)` applied to `ContentView()` inside `WindowGroup` (note: `preferredColorScheme` is a View modifier — it cannot be applied directly to `WindowGroup`)

## Happy path
- [ ] `project.pbxproj` contains zero occurrences of `firhanram.doksli` (old bundle ID without `com.` prefix)
- [ ] `project.pbxproj` contains zero occurrences of `MACOSX_DEPLOYMENT_TARGET = 15.1`
- [ ] App builds (`Cmd+B`) with no errors and no warnings about deployment target or bundle ID

## Edge cases
- [ ] Both Debug AND Release build configurations have the updated bundle ID — not just one
- [ ] Both Debug AND Release build configurations have the updated deployment target — not just one
- [ ] Entitlements `com.apple.security.network.client` is `<true/>` not `<false/>`

## Failure cases
- [ ] App sandbox entitlement `com.apple.security.app-sandbox` is still `<true/>` — must NOT be removed
- [ ] `com.apple.security.files.user-selected.read-only` is still present — must NOT be removed

## Constraints from CLAUDE.md
- [ ] `.preferredColorScheme(.light)` is applied to `ContentView()` inside `WindowGroup` — this is the correct SwiftUI placement (it is a View modifier, not a Scene modifier)
- [ ] Light mode only — not `.preferredColorScheme(.dark)` or removed entirely
- [ ] Bundle ID matches `com.firhanram.doksli` from CLAUDE.md Quick facts

## Does NOT do (out of scope)
- [ ] Does not change scheme names or build phases
- [ ] Does not add Swift packages or third-party dependencies
- [ ] Does not change code signing settings

## Integration
- [ ] Network entitlement required by `HTTPClient` (Phase 3) for outgoing `URLSession` requests
- [ ] Deployment target 13.0 required for `NavigationSplitView` (macOS 13+) and `ContinuousClock`
