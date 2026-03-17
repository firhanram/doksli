# Verification checklist — EnvEditorSheet

## Inputs & outputs
- [ ] Presented as `.sheet` from `ContentView`
- [ ] `@EnvironmentObject var appState: AppState`
- [ ] List+detail layout: environment list (left) + variable editor (right)

## Happy path
- [ ] Click "+" → creates new environment "New Environment", selects it
- [ ] Edit name → name updates in list, persists via `StorageService`
- [ ] Add variable → new row with empty key/value, enabled by default
- [ ] Edit variable key/value → persists on every keystroke
- [ ] Toggle variable enabled → persists immediately
- [ ] Delete variable (xmark) → removed from list, persists

## Edge cases
- [ ] No environments → empty list, right side shows placeholder text
- [ ] Delete all variables from an environment → empty variables list, no crash
- [ ] Long environment name → does not break layout

## Failure cases
- [ ] Delete environment → confirmation alert shown, removes on confirm
- [ ] Delete active environment → clears `appState.activeEnvironment`

## Constraints from CLAUDE.md
- [ ] No hardcoded hex colors — uses `AppColors` tokens only
- [ ] No hardcoded spacing — uses `AppSpacing` constants only
- [ ] No third-party imports
- [ ] Persistence via `StorageService` (atomic writes)

## Does NOT do (out of scope)
- [ ] Does not reuse `KVEditor` — uses `EnvVar` type, not `KVPair`
- [ ] Does not contain the env selector menu

## Integration
- [ ] Sheet controlled by `appState.showEnvEditor`
- [ ] `⌘E` opens the sheet via `ToolbarView`
- [ ] "Done" button dismisses sheet
- [ ] Changes persist to `~/.doksli/v1/environments.json`
