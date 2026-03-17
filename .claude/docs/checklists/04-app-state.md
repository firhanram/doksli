# Verification checklist — AppState observable object

## Inputs & outputs
- [ ] Class signature: `@MainActor class AppState: ObservableObject`
- [ ] File location: `Views/Shell/AppState.swift`
- [ ] No init parameters — all defaults are empty/nil/false

## Happy path
- [ ] `workspaces: [Workspace]` — default `[]`, setting to `[ws]` triggers view update
- [ ] `selectedWorkspace: Workspace?` — default `nil`, setting triggers view update
- [ ] `selectedRequest: Request?` — default `nil`, setting triggers view update
- [ ] `activeEnvironment: Environment?` — default `nil`, setting triggers view update
- [ ] `pendingResponse: Response?` — default `nil`, setting triggers view update
- [ ] `isLoading: Bool` — default `false`, setting to `true` triggers view update

## Edge cases
- [ ] All 6 properties are `@Published` — each one individually triggers `objectWillChange`
- [ ] Class is annotated `@MainActor` — all mutations guaranteed on main thread
- [ ] `AppState()` can be instantiated without arguments — no required parameters

## Failure cases
- [ ] Attempting to set a `@Published` property from a background thread → compiler warning with `@MainActor`
- [ ] Removing `@MainActor` → potential data races with async code in later phases

## Constraints from CLAUDE.md
- [ ] No third-party imports — `import SwiftUI` only
- [ ] No business logic inside AppState — no methods that call services, no file I/O, no network
- [ ] No local `@State` for cross-view data — everything is in AppState

## Does NOT do (out of scope)
- [ ] Does not call `StorageService` — data loading wired in later phases
- [ ] Does not call `HTTPClient` — request sending wired in Phase 6
- [ ] Does not contain computed properties or methods with logic
- [ ] Does not contain `lastError: Error?` — added in Phase 9

## Integration
- [ ] Referenced types compile: `Workspace`, `Request`, `Environment`, `Response` (all from Phase 1 Models)
- [ ] Injected at root via `@StateObject` in `doksliApp.swift`
- [ ] Consumed via `@EnvironmentObject` in `ContentView`
