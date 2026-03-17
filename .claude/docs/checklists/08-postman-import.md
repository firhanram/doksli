# Verification checklist — PostmanImporter

## Inputs & outputs
- [ ] Input: `URL` pointing to a Postman environment JSON file
- [ ] Output: `Environment` model (throws on invalid format)
- [ ] Signature: `static func importEnvironment(from url: URL) throws -> Environment`

## Happy path
- [ ] Valid Postman JSON `{"name":"Prod","values":[{"key":"url","value":"https://api.com","enabled":true}]}` → `Environment` with name "Prod" and 1 enabled variable
- [ ] Multiple values → all mapped to `EnvVar` with correct key/value/enabled

## Edge cases
- [ ] Postman file with extra fields (id, _postman_variable_scope) → ignored, import succeeds
- [ ] Empty values array → Environment with empty variables list
- [ ] Disabled variable → `enabled: false` preserved

## Failure cases
- [ ] Invalid JSON → throws `ImportError.invalidFormat`
- [ ] Missing required fields (no "name" or "values") → throws `ImportError.invalidFormat`
- [ ] File not found → throws `ImportError.invalidFormat`

## Constraints from CLAUDE.md
- [ ] No third-party imports — Foundation only
- [ ] No SwiftUI dependency — pure service
- [ ] No business logic in views — import logic in `PostmanImporter`

## Does NOT do (out of scope)
- [ ] Does not import Postman collections — only environments
- [ ] Does not open file dialog — that's the view's responsibility

## Integration
- [ ] Called from `EnvEditorSheet` "Import from Postman" button
- [ ] `NSOpenPanel` filters to `.json` in the view layer
- [ ] Error surfaced via `.alert` in the sheet
