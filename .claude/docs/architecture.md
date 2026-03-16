# Architecture

Zero third-party dependencies. Everything is Foundation + SwiftUI.

---

## Tech stack

| Layer | Technology | Why |
|---|---|---|
| UI | SwiftUI | Native, zero overhead, macOS 13+ |
| Navigation | `NavigationSplitView` | Built-in 3-column layout, collapsible |
| Networking | `URLSession` async/await | Full control over headers, redirects, TLS |
| Persistence | `JSONEncoder` / `JSONDecoder` | Simple, no Core Data complexity |
| Regex | `NSRegularExpression` (macOS 13) | Built-in, no libs needed |
| JSON parsing | `JSONSerialization` | Foundation native, handles dynamic structure |
| Timing | `ContinuousClock` | High-precision, available from macOS 13 |

---

## Data models

All models are `Codable` structs. Define these before writing any View.

### Workspace tree

```
Workspace
  └── collections: [Collection]
        └── items: [Item]          ← recursive enum
              ├── .folder(Folder)
              │     └── items: [Item]
              └── .request(Request)
```

### Request

```swift
struct Request: Codable, Identifiable {
    var id: UUID
    var name: String
    var method: HTTPMethod          // enum: GET POST PUT DELETE PATCH OPTIONS HEAD
    var url: String                 // raw string — may contain {{vars}}
    var params: [KVPair]
    var headers: [KVPair]
    var body: RequestBody           // enum: none / raw(String) / formData([KVPair]) / urlEncoded([KVPair])
    var auth: Auth                  // enum: none / bearer(String) / basic(String,String) / apiKey(String,String)
}

struct KVPair: Codable, Identifiable {
    var id: UUID
    var key: String
    var value: String
    var enabled: Bool
}
```

### Response

```swift
struct Response {
    var statusCode: Int
    var headers: [KVPair]
    var body: Data
    var durationMs: Double
    var sizeBytes: Int             // body.count
}
```

### Environment

```swift
struct Environment: Codable, Identifiable {
    var id: UUID
    var name: String
    var variables: [EnvVar]
}

struct EnvVar: Codable, Identifiable {
    var id: UUID
    var key: String
    var value: String
    var enabled: Bool
}
```

### HistoryEntry

```swift
struct HistoryEntry: Codable, Identifiable {
    var id: UUID
    var request: Request
    var response: Response         // Response must also be Codable
    var timestamp: Date
}
```

---

## Services

### HTTPClient

Headless — no SwiftUI dependency. Builds `URLRequest`, executes, measures, maps response.

```
Input:  Request + active Environment
Output: Response (async throws)

Steps:
1. VariableResolver.resolve(request, environment)   → resolved copy
2. Build URLRequest from resolved Request
3. ContinuousClock.measure { URLSession.data(for:) }
4. Map HTTPURLResponse → Response model
```

**Never** mutates the original `Request` — always resolves into a copy.

### VariableResolver

```
Input:  String + [EnvVar]
Output: String with {{key}} tokens replaced

Rules:
- Only substitutes enabled variables
- Unknown variables left as-is (not stripped)
- Applied to: URL, header values, body raw string
- Not applied to: header keys, param keys
```

### StorageService

Atomic writes only — never write directly to the target file.

```
Pattern:
1. Encode to Data
2. Write to temp file (same directory)
3. rename(temp, target)   ← atomic on APFS/HFS+

Files:
~/.doksli/v1/workspaces.json
~/.doksli/v1/environments.json
~/.doksli/v1/history.json        ← ring buffer, max 100 entries
~/.doksli/v1/VERSION             ← schema version integer
```

### PostmanImporter

Decodes Postman's environment export format into Doksli's `Environment` model.

```json
{
  "name": "Production",
  "values": [
    { "key": "base_url", "value": "https://api.example.com", "enabled": true }
  ]
}
```

---

## App state

Single `AppState` observable object, injected at root via `@StateObject`.

```swift
class AppState: ObservableObject {
    @Published var workspaces: [Workspace]
    @Published var selectedWorkspace: Workspace?
    @Published var selectedRequest: Request?
    @Published var activeEnvironment: Environment?
    @Published var pendingResponse: Response?
    @Published var isLoading: Bool
    @Published var lastError: Error?
}
```

No local `@State` for anything that crosses view boundaries. If two views need to agree on a value, it lives in `AppState`.

---

## Phase dependency chain

```
0 Setup
  └── 1 Models (Codable structs — no UI dependency)
        ├── 2 Storage (pure Swift — unit testable in isolation)
        └── 3 HTTP Client (pure Swift — unit testable in isolation)
              └── 4 App Shell (NavigationSplitView + AppState)
                    ├── 5 Sidebar
                    ├── 6 Request Editor
                    └── 7 Response Viewer
                          └── 8 Environments (needs 3 + 6)
                                └── 9 Polish
```

Build and test phases 1–3 before opening Xcode's canvas. Bugs in the data layer are invisible inside a UI.

---

## Keyboard shortcuts

Defined in one place (`ToolbarView.swift`) before being bound to any view.

| Action | Shortcut |
|---|---|
| Send request | `⌘↵` |
| New request | `⌘N` |
| New folder | `⌘⇧N` |
| Clear response | `⌘K` |
| Open env editor | `⌘E` |
| Duplicate request | `⌘D` |
