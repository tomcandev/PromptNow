# PRODUCT REQUIREMENTS DOCUMENT (PRD) — MVP

| Field | Value |
|---|---|
| **Project Name** | PromptNow |
| **PRD Version** | 2.0 |
| **Last Updated** | 2026-04-09 |
| **Author** | Tom |
| **MVP Platform** | macOS (Native — Swift 100%) |
| **Minimum OS** | macOS 14 Sonoma or later |
| **License** | MIT (inherited from Maccy) |
| **Positioning** | A "Spotlight" for storing & quickly retrieving AI Prompts |

---

## 1. Overview & Objectives

### 1.1 Problem Statement
Power users working extensively with AI (ChatGPT, Claude, Cursor, Gemini, etc.) experience **repetitive friction** every time they need to use a pre-written prompt:

1. Open a note-taking app (Notes, Notion, Obsidian...)
2. Search for the prompt among dozens/hundreds of notes
3. Highlight → Copy
4. Return to the AI window → Paste

> **On average, each instance takes 15-30 seconds.** If using AI 50+ times a day, that represents **12-25 minutes of wasted time** just "fetching the right prompt".

### 1.2 Solution
**PromptNow** is a macOS menu-bar application that enables users to:
- Press a **single global hotkey** (`Option + Space`) to trigger a minimalist Spotlight-like interface
- Type a few characters to instantly find the right prompt
- Press `Enter` to copy it to the clipboard
- The entire flow is **completed in < 3 seconds**, entirely keyboard-driven

### 1.3 MVP Goals
- ✅ Build the fastest possible **search → copy** workflow
- ✅ Remove system permission barriers (do not rely on Accessibility privileges for the MVP)
- ✅ MVP Development timeframe: **< 2 weeks**
- ✅ Develop a highly usable personal productivity tool prior to wider distribution

### 1.4 Target Users
| Persona | Description |
|---|---|
| **AI Power User** | Devs/Designers using AI IDEs (Cursor, Windsurf) daily, maintaining their own prompt libraries |
| **Content Creator** | Marketers, copywriters leveraging ChatGPT/Claude for content generation, utilizing prompt templates |
| **Productivity Enthusiast** | Raycast/Alfred power users who prefer a keyboard-first workflow |

---

## 2. Technical Strategy

### 2.1 Core Codebase: Forked from Maccy
| Attribute | Details |
|---|---|
| **Original Repository** | [`p0deje/Maccy`](https://github.com/p0deje/Maccy) (19.3k ⭐, MIT License) |
| **Reference Version** | v2.6.1 (latest stable) |
| **Language** | Swift 100% |
| **UI Framework** | SwiftUI (Maccy 2.0+) |
| **Persistence** | SwiftData |

### 2.2 Refactoring Strategy: Maccy → PromptNow

#### ✅ RETAINED from Maccy
- Core **Global Hotkey** logic (default mapped to `Option + Space`)
- **Menu Bar Icon** + status bar behavior
- **Borderless floating window** UI paradigm
- **Search/Filter UI** fundamentals (search bar + results list)
- Keyboard navigation (Arrow keys, Enter, Escape)
- **Preferences window** framework
- Dark Mode / Light Mode dynamic switching
- SwiftUI view architecture
- App lifecycle logic (launch at login, persistent background execution)

#### ❌ REMOVED from Maccy
- **NSPasteboard polling** — the entire clipboard listening module (500ms timer, clipboard checks)
- **Clipboard history storage** — SwiftData models pertaining to clipboard history logs
- **Pin/Unpin** UI and logic for items
- **Auto-paste logic** (eliminating the need for Accessibility permissions)
- **Image/file support** — PromptNow focuses exclusively on plain text
- **Clipboard ignore rules** (transient types, app-specific exclusion rules)
- **Universal Clipboard** strict handling

#### 🔄 REPLACED / MODIFIED
| Maccy (Original) | PromptNow (New) |
|---|---|
| Data source: `NSPasteboard` history | Data source: `prompts.json` static file via SwiftData sync |
| SwiftData `HistoryItem` model | SwiftData `Prompt` model (title, content, tags, category) |
| Copy from clipboard history to buffer | Copy static prompt content → general clipboard |
| Fuzzy search on raw clipboard text | Fuzzy search against title + content + tags |
| Default Hotkey: `Shift+Cmd+C` | Default Hotkey: `Option+Space` |
| Tooltip displays full clipboard text | Dedicated Preview pane renders full prompt content |

---

## 3. Core User Flow

```
┌─────────────────────────────────────────────────────────┐
│  1. RUNNING IN BACKGROUND                               │
│     Menu bar icon active in the status bar              │
│                                                         │
│  2. TRIGGER → Option + Space                            │
│     ┌─────────────────────────────────┐                 │
│     │ 🔍 Search prompts...            │ ← auto-focus   │
│     ├─────────────────────────────────┤                 │
│     │ ⭐ Refactoring Code        [coding]│              │
│     │    SEO Blog Outline    [marketing]│              │
│     │    Bug Report Template    [qa]    │              │
│     │    Email Response         [comm]  │              │
│     ├─────────────────────────────────┤                 │
│     │ Preview:                         │                │
│     │ "Act as a Senior Developer.      │                │
│     │  Refactor the following code..." │                │
│     └─────────────────────────────────┘                 │
│                                                         │
│  3. SEARCH → Type "refac"                               │
│     Realtime filtered results                           │
│                                                         │
│  4. SELECT → Arrow keys ↑↓ to navigate                 │
│     Preview updates dynamically based on selection      │
│                                                         │
│  5. EXECUTE → Press Enter                               │
│     ✓ Content copied to clipboard                       │
│     ✓ Toast notification "Copied!" (auto-hides in 1.5s) │
│     ✓ Search window automatically closes                │
│                                                         │
│  6. PASTE → Cmd+V inside ChatGPT/Claude/Cursor          │
└─────────────────────────────────────────────────────────┘
```

---

## 4. Detailed Functional Requirements

### 4.1 Menu Bar & App Lifecycle
| Requirement | Details |
|---|---|
| **Menu Bar Icon** | Minimalist icon residing in the macOS status bar (`pencil.and.outline` SF Symbol) |
| **Left-click icon** | Toggles the main Search Window visibility |
| **Right-click icon** | Exposes Contextual menu: `Preferences…`, `About PromptNow`, `Quit` |
| **Launch at Login** | Configurable toggle inside Preferences, defaults to OFF |
| **Background execution** | Operates stealthily without a persistent Dock icon |

### 4.2 Search Window (Main UI)
| Requirement | Details |
|---|---|
| **Window style** | Borderless, floating utility panel, stripped of standard window title bars |
| **Positioning** | Centered automatically on the active display (Spotlight paradigm) |
| **Backdrop** | High-quality vibrancy/blur effect (`NSVisualEffectView` underlays) |
| **Dimensions** | Fixed width ~600px, dynamically resizing height up to ~500px based on results |
| **Themeing** | Seamlessly adapts to system-wide Dark/Light appearance modes |
| **Radius** | Modern, generous border radiuses (~12px) |

### 4.3 Search & Filter Mechanics
| Requirement | Details |
|---|---|
| **Search field** | Automatically gains focus upon window activation |
| **Search scope** | Performs matches across: `title`, `content`, and `tags` |
| **Search algorithm** | Highly optimized Fuzzy search (e.g., typing "refac" natively surfaces "Refactoring Code") |
| **Realtime filtering** | List updates instantly with every keystroke; Enter key acts purely as execution |
| **Empty state behavior** | Displays all prompts prior to any text input |
| **Zero results** | Dedicated empty state view: "No prompts found. Try a different keyword." |
| **Visual emphasis** | Realtime highlight/bolding of characters directly matching the query string |

### 4.4 Results List Hierarchy
| Requirement | Details |
|---|---|
| **Row Anatomy** | Bold Title + Pill-shaped badge Tags (muted aesthetic) |
| **Subtitle Preview** | Truncated one-line snippet (first 50-80 chars) of the prompt content |
| **Selection state** | Distinct background highlight treatment for the focused row |
| **Visible capacity** | Comfortably displays 7-8 rows prior to requiring scroll interaction |
| **Scrolling** | Smooth kinetic scrolling, perfectly tracking with keyboard navigation |

### 4.5 Preview Pane
| Requirement | Details |
|---|---|
| **Placement** | Positioned directly beneath the results list, separated by a subtle visual divider |
| **Content rendering** | Displays the **entire un-truncated content** of the currently highlighted prompt row |
| **Update latency** | Instant, zero-delay rendering synchronously tied to ↑↓ arrow key navigation |
| **Typography** | Monospaced font application for clean readability (vital for coding prompts) |
| **Height constraints** | ~150px fixed maximum height; contents become scrollable for exceptionally long prompts |

### 4.6 Keyboard Navigation (Mouse-free Optimization)
| Keybinding | Action mapping |
|---|---|
| `Option + Space` | Global toggle for the Search Window (completely configurable) |
| `↑` / `↓` | Rapid vertical traversal through the filtered result list |
| `Enter` | Executes primary action: Copies full Prompt content to clipboard and dismisses UI |
| `Escape` | Dismisses window gracefully without polluting the clipboard |
| `⌘ + ,` | Triggers Preferences window |
| `⌘ + Q` | Halts execution gracefully |

### 4.7 Copy & Feedback Loop
| Requirement | Details |
|---|---|
| **Clipboard format** | Strict Plain Text copying (strips all source formatting issues) |
| **Target injection** | Directly writes to the macOS global `NSPasteboard.general` |
| **Visual feedback** | Non-blocking, glassmorphic Toast overlay "✓ Copied!" (Fades after 1.5s) |
| **Audio feedback** | Intentionally silent (avoids audible fatigue during high-frequency usage) |

### 4.8 Preferences Window Configuration
| Setting | Description | Default State |
|---|---|---|
| **Hotkey Mapper** | Native key-recorder to remap the global activation sequence | `Option + Space` |
| **Launch at Login** | System-level integration for auto-starting | OFF |
| **Storage Path** | Reference path locating the `prompts.json` DB | `~/Library/Application Support/PromptNow/prompts.json` |
| **Appearance** | Override rendering (Follow System / Dark / Light) | Follow System |

---

## 5. Persistence Architecture

### 5.1 Static Schema: `prompts.json`
*MVP heavily leverages a static JSON backbone for development velocity, mapped onto a SwiftData model container.*

```json
{
  "version": "1.0",
  "prompts": [
    {
      "id": "uuid-1",
      "title": "Refactoring Code",
      "content": "Act as a Senior Developer. Refactor the following code to improve performance and readability. Add comments explaining the changes:\n\n```\n[Paste your code here]\n```",
      "tags": ["coding", "refactor"],
      "category": "Development",
      "isFavorite": false,
      "createdAt": "2026-04-09T00:00:00Z",
      "updatedAt": "2026-04-09T00:00:00Z"
    }
  ]
}
```

### 5.2 Swift Native Data Model
```swift
struct Prompt: Identifiable, Codable {
    let id: String          // UUID string representation
    let title: String       // High-level searchable identifier
    let content: String     // The exact payload copied to clipboard
    let tags: [String]      // Filtering metadata identifiers
    let category: String    // Broad categorization grouping
    let isFavorite: Bool    // Forces item pin to the top of standard sorts
    let createdAt: String   // ISO 8601 formatting
    let updatedAt: String   // ISO 8601 formatting
}
```

### 5.3 Storage Paradigm
- **Default Location:** `~/Library/Application Support/PromptNow/prompts.json`
- **Initial Bootstrapping:** Application automatically generates the file mapped with 5 highly useful default generic prompts
- **MVP Editing Strategy:** Users perform manual CRUD editing directly inside the JSON file using standard VSCode/Sublime text editors

---

## 6. Non-Functional Requirements (NFRs)

| Metric | Target SLA |
|---|---|
| **Cold Boot Time** | < 1.0s from execution to Menu bar manifestation |
| **Global Hook Reactivity** | < 200ms TTFC (Time to First Character) post `Option+Space` |
| **Fuzzy Algorithm Speed** | < 50ms processing overhead for datasets matching < 500 nodes |
| **Memory Footprint** | Stable at < 30MB during passive background sleeping phases |
| **Binary Footprint** | Heavily optimized to < 10MB distribution bundle |
| **Telemetry & Privacy** | 100% offline edge execution, strictly zero network exfiltration capabilities |

---

## 7. Decoupled Requirements (Out of Scope for MVP)

> ⛔ The following scope requests are **STRICTLY PROHIBITED** from entering the MVP codebase parameters:

| Deferred Feature | Deferment Justification |
|---|---|
| **Auto-paste execution** | Mandates intensive macOS Accessibility privilege prompts, deeply fracturing simple onboarding |
| **iCloud/Remote Sync mechanisms** | Purely local execution required for V1 velocity |
| **In-app GUI Editor tools** | Manual JSON manipulation suffices. High UI overhead reserved for Phase 2 |
| **Notion/Obsidian parsers** | Out of scope mapping tasks |
| **Kotlin Multiplatform / Android port** | Deferring until rigorous Market-Fit validation established exclusively on macOS |
| **Dynamic Form Templates** | E.g., `{{topic}}` launching inline text input boxes — complex UI requirement for Phase 2 |
| **Snippet inline execution** | E.g., typing `/refac` inside a browser implicitly triggering OS replacement |
| **Side-panel Category Tabs** | Keyboard Fuzzy logic supersedes click-centric tabs presently |

---

## 8. Strategic Roadmap

### Phase 1: MVP Realization (Current — Target duration: 2 Weeks)
1. Safely clone/fork upstream `Maccy` repository and sever legacy hooks
2. Re-architect data conduit bypassing Pasteboard to `prompts.json` static ingestion
3. Restructure UX (Search bar + Result list + Persistent Preview module)
4. Standardize default runtime hooks (`Option + Space`)
5. Unify Clipboard writing pipeline + transparent Toast signaling
6. Consolidate Preferences
7. Auto-seed default DB configuration

### Phase 2: Enhanced Product (Post Market Validation)
- Full In-App UI for seamless Prompt generation/updates/deletions
- Lateral Category/Folder filtering components
- Implementation of dynamic inline variables (`{{placeholder}}`) templates
- Exportation and JSON backup tools
- Opt-in seamless iCloud data storage

### Phase 3: Cross-Platform Expansion
- Transition core logic to Kotlin Multiplatform (KMP)
- Android companion client application rollout
- Universally recognized shared data schema configuration

---

## 9. Addendum: Default Hotkey Strategy (`Option + Space`)

### Ergonomic Justification
1. **Inherited Muscle Memory:** Directly adjacent to macOS Spotlight behavior (`Cmd + Space`), maximizing adoption ease.
2. **Kinetic Velocity:** Comfortably executed singularly using standard left-hand resting positioning.
3. **Collision Avoidance:** Vastly circumvents standard global conflicts relative to alternative meta layouts (e.g. VSCode typical `Cmd+Shift+P`).

### Known Global Conflicts Matrix
| Target Platform | Default Hook | Severity |
|---|---|---|
| **macOS Native** | `Option+Space` renders invisible "non-breaking space" char | ⚠️ Negligible frequency of user intent |
| **Raycast App** | Frequently overridden by users to `Option+Space` | ⚠️ Moderate — necessitates binary user choice / explicit remapping |
| **Alfred** | Historically occupies `Option+Space` or `Cmd+Space` keyspace | ⚠️ Moderate |

### Conflict Mitigation Actions
- Core requirement: Unrestricted user re-mapping functionality hard-coded natively within Settings GUI.
- Post-MVP roadmap: Intelligent startup detection signaling potential 3rd-party port collision overrides.