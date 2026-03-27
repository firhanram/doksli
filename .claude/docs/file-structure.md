# File structure

```
Doksli/
│
├── CLAUDE.md                           # Claude Code entry point — keep short
│
├── docs/
│   ├── design-system.md
│   ├── architecture.md
│   ├── file-structure.md               # this file
│   └── todos.md
│
├── Doksli/
│   │
│   ├── App/
│   │   └── DoksliApp.swift             # @main, WindowGroup
│   │                                   # .preferredColorScheme driven by AppState.colorMode
│   │
│   ├── Models/
│   │   ├── Workspace.swift             # Workspace, Collection, Item (recursive enum)
│   │   ├── Request.swift               # Request, KVPair, HTTPMethod, RequestBody, Auth
│   │   ├── Response.swift              # Response — must be Codable for history
│   │   ├── Environment.swift           # Environment, EnvVar
│   │   └── HistoryEntry.swift          # HistoryEntry — snapshot of Request + Response
│   │
│   ├── Views/
│   │   │
│   │   ├── Shell/
│   │   │   ├── ContentView.swift       # Root NavigationSplitView (3 columns)
│   │   │   ├── AppState.swift          # @MainActor ObservableObject — single source of truth
│   │   │   └── ToolbarView.swift       # Env picker + keyboard shortcuts + window controls
│   │   │
│   │   ├── Sidebar/
│   │   │   ├── SidebarView.swift       # Workspace selector + tab bar + scroll area
│   │   │   ├── WorkspaceRow.swift      # Workspace header with dropdown
│   │   │   ├── FolderRow.swift         # Expandable folder row with chevron
│   │   │   ├── RequestRow.swift        # MethodBadge + name, active highlight
│   │   │   └── MethodBadge.swift       # Reusable pill — reads color from AppColors.method*
│   │   │
│   │   ├── Request/
│   │   │   ├── RequestView.swift       # Assembles URLBarView + TabBarView + tab panels
│   │   │   ├── URLBarView.swift        # Method Menu + URL TextField + Send button
│   │   │   ├── TabBarView.swift        # Custom segment control — NOT TabView
│   │   │   ├── KVEditor.swift          # Shared by Params + Headers + form-data body
│   │   │   │                           # Props: binding to [KVPair], optional placeholder
│   │   │   ├── BodyEditor.swift        # Sub-picker: none / raw / form-data / urlEncoded
│   │   │   └── AuthEditor.swift        # Sub-picker: none / bearer / basic / api-key
│   │   │                               # Bearer auto-injects Authorization header on send
│   │   │
│   │   ├── Response/
│   │   │   ├── ResponseView.swift      # StatsBarView + TabBarView + tab panels
│   │   │   ├── StatsBarView.swift      # Status code chip + ms chip + KB chip
│   │   │   │                           # Colors status by range: 2xx green, 3xx amber, 4xx/5xx red
│   │   │   ├── JSONTreeView.swift      # Recursive tree — calls JSONNode for each value
│   │   │   ├── JSONNode.swift          # One node: expand toggle, key label, value label
│   │   │   │                           # Click any value to copy to clipboard
│   │   │   ├── HeadersListView.swift   # Read-only KV list — click row to copy value
│   │   │   └── RawBodyView.swift       # ScrollView + SelectableText, SF Mono, copy-all btn
│   │   │
│   │   ├── Environment/
│   │   │   ├── EnvEditorSheet.swift    # .sheet — KVEditor + enabled toggles + save/cancel
│   │   │   │                           # "Import from Postman" button in footer
│   │   │   └── EnvSelectorMenu.swift   # Toolbar Menu — lists envs + "No environment"
│   │   │
│   │   ├── Settings/
│   │   │   └── SettingsView.swift      # .sheet — sidebar nav + Appearance section
│   │   │                               # Color mode picker: Automatic / Light / Dark
│   │   │
│   │   └── History/
│   │       └── HistoryView.swift       # List grouped by date, click to reload into editor
│   │
│   ├── Services/
│   │   ├── HTTPClient.swift            # URLSession wrapper
│   │   │                               # buildRequest(from:environment:) → URLRequest
│   │   │                               # send(_:) async throws → Response
│   │   │                               # Measures with ContinuousClock
│   │   │
│   │   ├── VariableResolver.swift      # resolve(string:environment:) → String
│   │   │                               # Regex: NSRegularExpression, pattern \{\{(\w+)\}\}
│   │   │                               # Returns copy — never mutates input
│   │   │
│   │   ├── StorageService.swift        # load/save workspaces, environments, history
│   │   │                               # Atomic write: encode → temp file → rename
│   │   │                               # History capped at 100 entries (ring buffer)
│   │   │
│   │   └── PostmanImporter.swift       # importEnvironment(from url: URL) → Environment
│   │                                   # Decodes { values: [{ key, value, enabled }] }
│   │
│   └── Resources/
│       ├── Assets.xcassets             # App icon only — all colors are in AppColors.swift
│       ├── AppColors.swift             # static let canvas = Color(hex: "#FDFCFA") etc.
│       ├── AppFonts.swift              # static let mono = Font.system(size: 12, design: .monospaced)
│       └── AppSpacing.swift            # static let lg: CGFloat = 16
│
└── DoksliTests/
    ├── VariableResolverTests.swift     # Unit — resolve known vars, unknown vars, empty env
    ├── StorageServiceTests.swift       # Unit — encode → decode round-trip per model
    └── HTTPClientTests.swift           # Integration — GET/POST against httpbin.org
```

---

## Naming conventions

- Views: `NounView.swift` (e.g. `RequestView`, `SidebarView`)
- Sheets: `NounSheet.swift` (e.g. `EnvEditorSheet`)
- Rows: `NounRow.swift` (e.g. `RequestRow`, `FolderRow`)
- Reusable components: noun only (e.g. `MethodBadge`, `KVEditor`, `TabBarView`)
- Services: `NounService.swift` or `NounClient.swift`
- Models: plain noun (e.g. `Request.swift`, `Environment.swift`)

## What NOT to put in Views

- Network calls — belongs in `HTTPClient`
- File I/O — belongs in `StorageService`
- Variable substitution — belongs in `VariableResolver`
- Business logic — belongs in the relevant Service

Views own: layout, bindings, animation, user input routing.
