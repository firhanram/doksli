# Verification checklist — EnvSelectorMenu

## Inputs & outputs
- [ ] `@ObservedObject var appState: AppState`
- [ ] Returns a `Menu` view for toolbar placement

## Happy path
- [ ] "No Environment" shown at top with checkmark when no env active
- [ ] All environments listed below divider
- [ ] Click environment → `appState.activeEnvironment` updated, toolbar label changes
- [ ] Active environment shows checkmark
- [ ] "Edit Environments…" at bottom opens env editor sheet

## Edge cases
- [ ] No environments saved → only "No Environment" and "Edit Environments…" shown
- [ ] Switch between environments → checkmark moves correctly

## Failure cases
- [ ] N/A — Menu is a simple list of buttons

## Constraints from CLAUDE.md
- [ ] No hardcoded colors or spacing — uses design tokens
- [ ] No third-party imports

## Does NOT do (out of scope)
- [ ] Does not edit environments — delegates to `EnvEditorSheet`
- [ ] Does not persist selection — `activeEnvironment` is in-memory only

## Integration
- [ ] Embedded in `ToolbarView` as `ToolbarItem(.primaryAction)`
- [ ] Replaces previous inline Menu placeholder
