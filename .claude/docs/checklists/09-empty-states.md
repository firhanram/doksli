# Verification checklist — Empty States

## Happy path
- [ ] No workspace selected → sidebar shows "No workspace selected" with tray icon
- [ ] Workspace exists but no requests/folders → shows "No requests yet" + "Press ⌘N to create one"
- [ ] No request selected → center panel shows "Select a request" with arrow icon
- [ ] No response yet → right panel shows "Send a request to see the response" with paperplane icon
- [ ] Empty history → History tab shows "No history yet" with clock icon

## Styling
- [ ] All icons use `AppColors.textFaint`
- [ ] All text uses `AppColors.textTertiary` or `AppColors.textPlaceholder`
- [ ] All text uses `AppFonts.body` or `AppFonts.eyebrow`
- [ ] No hardcoded colors or spacing

## Does NOT do
- [ ] Does not add empty states for individual tabs (params, headers, etc.)
