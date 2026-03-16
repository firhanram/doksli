# Verification checklist — Folder structure

## Inputs & outputs
- [ ] `doksli/Resources/` directory exists
- [ ] `doksli/Views/Shell/` directory exists
- [ ] `doksli/Views/Sidebar/` directory exists
- [ ] `doksli/Views/Request/` directory exists
- [ ] `doksli/Views/Response/` directory exists
- [ ] `doksli/Views/Environment/` directory exists
- [ ] `doksli/Views/History/` directory exists
- [ ] `doksli/Services/` directory exists

## Happy path
- [ ] `doksli/Views/Shell/ContentView.swift` exists (moved from `doksli/ContentView.swift`) — app still builds after the move
- [ ] Xcode project builds clean after all directories are created — no "file not found" errors
- [ ] All 8 new directories are visible as groups in Xcode Navigator (auto-discovered via PBXFileSystemSynchronizedRootGroup)

## Edge cases
- [ ] `doksli/ContentView.swift` (old root location) no longer exists — file has been moved, not copied
- [ ] No extra directories created beyond what file-structure.md specifies
- [ ] `doksli/Models/` directory still intact with all 5 Phase 1 files — not accidentally moved or deleted

## Failure cases
- [ ] If `ContentView.swift` is deleted rather than moved, the build will fail — verify the file exists at the new path before removing the old one

## Constraints from CLAUDE.md
- [ ] Directory names match `file-structure.md` exactly (case-sensitive: `Resources`, `Views`, `Services`)
- [ ] No new Swift files added to Views/ or Services/ subdirs yet — those come in Phases 4–8
- [ ] `Models/` directory already exists and must remain untouched

## Does NOT do (out of scope)
- [ ] Does not create `App/` directory — `doksliApp.swift` stays at the `doksli/` root
- [ ] Does not create placeholder .swift files in empty directories (Xcode shows them as empty groups)
- [ ] Does not modify `project.pbxproj` — PBXFileSystemSynchronizedRootGroup auto-discovers all directories

## Integration
- [ ] `Resources/` must exist before `AppColors.swift`, `AppFonts.swift`, `AppSpacing.swift` are created (task 4–6)
- [ ] `Views/Shell/` must exist before Phase 4 creates `ContentView.swift`, `AppState.swift`, `ToolbarView.swift`
- [ ] `Services/` must exist before Phase 2 creates `StorageService.swift`
