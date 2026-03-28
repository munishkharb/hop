# Hop - macOS Browser Picker

**Date:** 2026-03-29
**Status:** Approved
**Platform:** macOS (Apple Silicon + Intel)
**Language:** Swift + SwiftUI
**Min macOS:** 13.0 (Ventura)

---

## Overview

Hop is a native, lightweight macOS browser picker. When you click a link anywhere on your system, Hop intercepts it, checks your rules, and either auto-opens in the right browser or shows a floating picker panel for you to choose.

## Core Principles

- Native Swift/SwiftUI -- no Electron, no dependencies
- Menu bar app only -- no dock icon, no main window
- Sub-10MB memory footprint when idle
- Instant picker display (<50ms)

---

## Features

### 1. URL Interception

- Registers as macOS default browser (handles `http`/`https` URL schemes)
- All external link clicks route through Hop
- Hop never renders web content -- it only routes URLs

### 2. Rule Engine

- Rules evaluated top-to-bottom, first match wins
- Each rule has: pattern, target browser, enabled/disabled toggle
- Pattern types:
  - **Domain match:** `example.com` -- matches any URL with this domain/subdomain
  - **Domain + path:** `github.com/my-org/*` -- matches domain with path glob
- When a rule matches: URL opens silently in the target browser (no picker shown)
- When no rule matches: picker panel is displayed

### 3. Picker Panel

- Floating borderless NSPanel, ~300px wide
- Appears at cursor position
- Contents:
  - URL displayed at top (truncated with ellipsis if long)
  - Row of browser icons, each with a number label (1, 2, 3...)
  - Subtle hint: "Hold Option for private window"
- Interaction:
  - Click a browser icon to open
  - Press number key (1, 2, 3...) to open in corresponding browser
  - Hold Option + click/number to open in private/incognito window
  - Escape or click outside to cancel/dismiss
- Dismisses immediately after selection

### 4. Private/Incognito Support

- Hold Option modifier when selecting a browser
- Opens URL with browser-specific private flag:
  - Chrome/Chrome Beta: `--incognito`
  - Brave: `--incognito`
  - Firefox: `-private-window`
  - Safari: (not supported via CLI)
- URLs opened in private mode are **excluded from history**

### 5. Browser Detection

- Auto-detects installed browsers using `LSCopyApplicationURLsForURL`
- Supported browsers: Chrome, Chrome Beta, Brave, Firefox, Safari, Arc, Edge, Chromium, and any Chromium-based browser
- User can reorder browsers in settings (order determines number key assignment)
- Re-scans on settings open or app launch

### 6. Menu Bar

- Small menu bar icon (arrow/link icon)
- Click to show dropdown:
  - Recent history (last 10 URLs, excluding incognito)
  - Divider
  - Settings...
  - Enabled/Disabled toggle
  - Quit Hop

### 7. History

- Stores last 50 URLs with: timestamp, URL, browser used
- Excludes URLs opened in private/incognito mode
- Viewable from menu bar (last 10) and settings (full list)
- Click a history item to re-open in the same browser
- Clear history button in settings

### 8. Rule Management (Settings Window)

- SwiftUI settings window
- Tabs: Rules | Browsers | History | General
- **Rules tab:**
  - Table: Pattern | Browser | Enabled toggle
  - Add button: text field for pattern, dropdown for target browser
  - Edit inline or via sheet
  - Delete with button or swipe
  - Drag to reorder priority (first match wins)
- **Browsers tab:**
  - List of detected browsers with icons
  - Drag to reorder (changes number key assignment in picker)
  - Re-detect button
- **History tab:**
  - Full list of last 50 URLs
  - Click to re-open
  - Clear all button
- **General tab:**
  - Launch at login toggle
  - Menu bar icon style
  - Import rules from Velja (reads com.sindresorhus.Velja defaults)

### 9. Velja Migration

- On first launch, detect if Velja rules exist in UserDefaults
- Offer to import: parse Velja's rule JSON format and convert to Hop rules
- Existing Velja rules to migrate:
  - `example.com` -> Chrome Beta
  - `example.org` -> Chrome Beta
  - `example.net` -> Chrome Beta
  - `slack.com` -> Chrome Beta

---

## Architecture

### Components

| Component | File | Purpose |
|---|---|---|
| HopApp | `HopApp.swift` | App entry point, menu bar setup, URL handler registration |
| URLRouter | `URLRouter.swift` | Receives URLs, evaluates rules, decides: auto-open or show picker |
| RuleEngine | `RuleEngine.swift` | Pattern matching logic, rule evaluation |
| PickerPanel | `PickerPanel.swift` | Floating NSPanel, browser icons, keyboard handling |
| BrowserDetector | `BrowserDetector.swift` | Scans system for installed browsers |
| SettingsView | `Settings/SettingsView.swift` | SwiftUI settings window with tabs |
| RulesSettingsView | `Settings/RulesSettingsView.swift` | Rule management UI |
| BrowsersSettingsView | `Settings/BrowsersSettingsView.swift` | Browser ordering UI |
| HistorySettingsView | `Settings/HistorySettingsView.swift` | History viewer |
| GeneralSettingsView | `Settings/GeneralSettingsView.swift` | General preferences |
| HistoryStore | `HistoryStore.swift` | Persists recent URL history |
| VeljaMigrator | `VeljaMigrator.swift` | Imports rules from Velja |
| Models | `Models.swift` | Rule, Browser, HistoryEntry data models |

### Data Flow

```
Link clicked anywhere in macOS
  |
  v
macOS sends URL to Hop (registered default browser)
  |
  v
URLRouter.handle(url)
  |
  v
RuleEngine.evaluate(url, rules)
  |
  +--> Match found --> open(url, in: targetBrowser)
  |                        |
  |                        +--> Add to history (unless incognito)
  |
  +--> No match --> PickerPanel.show(at: cursorPosition, url: url)
                        |
                        v
                    User selects browser (click or keyboard)
                        |
                        +--> Option held? --> open in private mode, skip history
                        +--> Normal --> open(url, in: selectedBrowser), add to history
```

### Data Storage

- **Rules:** `~/Library/Application Support/Hop/rules.json`
- **Preferences:** `UserDefaults` (browser order, launch at login, etc.)
- **History:** `~/Library/Application Support/Hop/history.json`

### Info.plist Configuration

```xml
<!-- Register as browser -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>http</string>
      <string>https</string>
    </array>
  </dict>
</array>
```

---

## Non-Goals

- No web rendering -- Hop never loads web pages
- No sync across devices
- No extension/plugin system
- No URL modification/redirect
- No analytics or telemetry
