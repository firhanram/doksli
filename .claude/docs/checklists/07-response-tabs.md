# Verification checklist — Response TabBarView

## Inputs & outputs
- [ ] Reuses generic `TabBarView<Tab>` from Phase 6
- [ ] `ResponseTab` enum with cases: `.body`, `.headers`, `.raw`
- [ ] Each tab has a `label` property returning display string

## Happy path
- [ ] Body tab selected → shows `JSONTreeView` for JSON responses
- [ ] Body tab selected → shows `RawBodyView` for non-JSON responses
- [ ] Headers tab selected → shows `HeadersListView`
- [ ] Raw tab selected → shows `RawBodyView`

## Edge cases
- [ ] Switching tabs preserves response data (no re-fetch)
- [ ] Tab selection resets when new response arrives (stays on current tab)

## Failure cases
- [ ] Invalid tab state → cannot occur, enum is exhaustive

## Constraints from CLAUDE.md
- [ ] NOT using `TabView` — uses custom `TabBarView` segment control
- [ ] Active tab underline in `AppColors.brand`
- [ ] No hardcoded colors or spacing

## Does NOT do (out of scope)
- [ ] Does not include Cookies or Preview tabs (polish phase)
- [ ] Does not own the stats bar — that's `StatsBarView`

## Integration
- [ ] `ResponseView` owns `@State activeTab: ResponseTab`
- [ ] `TabBarView` receives `tabs`, `activeTab` binding, and `label` closure
