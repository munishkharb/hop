# Hop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS browser picker that intercepts URLs, routes them via rules, and shows a floating picker for unmatched URLs.

**Architecture:** Swift Package Manager project with SwiftUI for settings UI and AppKit NSPanel for the picker. Menu bar app (LSUIElement) that registers as a browser via URL schemes. Data persisted as JSON files in Application Support.

**Tech Stack:** Swift 6.2, SwiftUI, AppKit (NSPanel), Swift Package Manager, XCTest

---

## File Structure

```
Hop/
├── Package.swift
├── Sources/
│   └── Hop/
│       ├── HopApp.swift              -- App entry, menu bar, URL handler
│       ├── Models.swift              -- Rule, Browser, HistoryEntry structs
│       ├── BrowserDetector.swift     -- Scan system for installed browsers
│       ├── RuleEngine.swift          -- URL pattern matching
│       ├── URLRouter.swift           -- Route URL: rule match → open, no match → picker
│       ├── BrowserLauncher.swift     -- Open URL in browser (normal + private)
│       ├── HistoryStore.swift        -- Persist last 50 URLs as JSON
│       ├── RuleStore.swift           -- Persist rules as JSON
│       ├── PickerPanel.swift         -- Floating NSPanel with browser icons + keyboard
│       ├── PickerViewController.swift -- NSViewController hosting SwiftUI picker content
│       ├── VeljaMigrator.swift       -- Import rules from Velja defaults
│       ├── Settings/
│       │   ├── SettingsView.swift    -- TabView container
│       │   ├── RulesSettingsView.swift
│       │   ├── BrowsersSettingsView.swift
│       │   ├── HistorySettingsView.swift
│       │   └── GeneralSettingsView.swift
│       └── Resources/
│           └── Info.plist
├── Tests/
│   └── HopTests/
│       ├── RuleEngineTests.swift
│       ├── BrowserDetectorTests.swift
│       ├── HistoryStoreTests.swift
│       ├── RuleStoreTests.swift
│       ├── URLRouterTests.swift
│       ├── VeljaMigratorTests.swift
│       └── BrowserLauncherTests.swift
└── docs/
    ├── specs/
    │   └── 2026-03-29-hop-design.md
    └── plans/
        └── 2026-03-29-hop-implementation.md
```

---

## Task 1: Project Scaffold + Models

**Files:**
- Create: `Package.swift`
- Create: `Sources/Hop/Models.swift`
- Create: `Sources/Hop/Resources/Info.plist`
- Create: `Sources/Hop/HopApp.swift` (minimal stub)
- Create: `Tests/HopTests/RuleEngineTests.swift` (empty placeholder)

- [ ] **Step 1: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Hop",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Hop",
            path: "Sources/Hop",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "HopTests",
            dependencies: ["Hop"],
            path: "Tests/HopTests"
        ),
    ]
)
```

- [ ] **Step 2: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.hop.browserPicker</string>
    <key>CFBundleName</key>
    <string>Hop</string>
    <key>CFBundleDisplayName</key>
    <string>Hop</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Hop</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>Web URL</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>http</string>
                <string>https</string>
            </array>
        </dict>
    </array>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>HTML Document</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.html</string>
                <string>public.xhtml</string>
                <string>public.url</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

- [ ] **Step 3: Create Models.swift**

```swift
import Foundation

struct Browser: Identifiable, Codable, Equatable {
    let id: String          // bundle identifier, e.g. "com.google.Chrome.beta"
    let name: String        // display name, e.g. "Chrome Beta"
    let path: URL           // path to .app bundle
    let privateFlag: String? // CLI flag for private mode, e.g. "--incognito"

    var icon: NSImage? {
        NSWorkspace.shared.icon(forFile: path.path)
    }
}

struct Rule: Identifiable, Codable {
    let id: UUID
    var pattern: String         // e.g. "example.com" or "github.com/my-org/*"
    var browserID: String       // bundle identifier of target browser
    var isEnabled: Bool

    init(pattern: String, browserID: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.pattern = pattern
        self.browserID = browserID
        self.isEnabled = isEnabled
    }
}

struct HistoryEntry: Identifiable, Codable {
    let id: UUID
    let url: String
    let browserID: String
    let timestamp: Date

    init(url: String, browserID: String) {
        self.id = UUID()
        self.url = url
        self.browserID = browserID
        self.timestamp = Date()
    }
}
```

- [ ] **Step 4: Create minimal HopApp.swift stub**

```swift
import SwiftUI

@main
struct HopApp: App {
    var body: some Scene {
        MenuBarExtra("Hop", systemImage: "arrow.trianglehead.branch") {
            Text("Hop is running")
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
}
```

- [ ] **Step 5: Build to verify scaffold**

Run: `cd ~/hop && swift build 2>&1`
Expected: Build succeeds with no errors.

- [ ] **Step 6: Commit**

```bash
cd ~/hop
git init
git add Package.swift Sources/ Tests/ docs/
git commit -m "feat: project scaffold with models and Info.plist"
```

---

## Task 2: Browser Detection

**Files:**
- Create: `Sources/Hop/BrowserDetector.swift`
- Create: `Tests/HopTests/BrowserDetectorTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// Tests/HopTests/BrowserDetectorTests.swift
import XCTest
@testable import Hop

final class BrowserDetectorTests: XCTestCase {

    func testDetectsAtLeastOneBrowser() {
        let detector = BrowserDetector()
        let browsers = detector.detectBrowsers()
        XCTAssertFalse(browsers.isEmpty, "Should detect at least Safari on any Mac")
    }

    func testDetectedBrowsersHaveRequiredFields() {
        let detector = BrowserDetector()
        let browsers = detector.detectBrowsers()
        for browser in browsers {
            XCTAssertFalse(browser.id.isEmpty, "Bundle ID should not be empty")
            XCTAssertFalse(browser.name.isEmpty, "Name should not be empty")
            XCTAssertTrue(FileManager.default.fileExists(atPath: browser.path.path), "App path should exist")
        }
    }

    func testSafariIsDetected() {
        let detector = BrowserDetector()
        let browsers = detector.detectBrowsers()
        let safari = browsers.first(where: { $0.id == "com.apple.Safari" })
        XCTAssertNotNil(safari, "Safari should always be detected")
        XCTAssertEqual(safari?.name, "Safari")
    }

    func testPrivateFlagsAssigned() {
        let detector = BrowserDetector()
        let browsers = detector.detectBrowsers()

        if let chrome = browsers.first(where: { $0.id.contains("com.google.Chrome") }) {
            XCTAssertEqual(chrome.privateFlag, "--incognito")
        }
        if let brave = browsers.first(where: { $0.id.contains("com.brave.Browser") }) {
            XCTAssertEqual(brave.privateFlag, "--incognito")
        }
    }

    func testNoDuplicateBundleIDs() {
        let detector = BrowserDetector()
        let browsers = detector.detectBrowsers()
        let ids = browsers.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Should not have duplicate bundle IDs")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd ~/hop && swift test --filter BrowserDetectorTests 2>&1`
Expected: FAIL — `BrowserDetector` not found.

- [ ] **Step 3: Implement BrowserDetector**

```swift
// Sources/Hop/BrowserDetector.swift
import AppKit

final class BrowserDetector {

    // Known browsers with their private-mode CLI flags
    private static let privateFlagMap: [String: String] = [
        "com.google.Chrome": "--incognito",
        "com.google.Chrome.beta": "--incognito",
        "com.google.Chrome.canary": "--incognito",
        "com.brave.Browser": "--incognito",
        "com.brave.Browser.beta": "--incognito",
        "com.brave.Browser.nightly": "--incognito",
        "com.microsoft.edgemac": "--inprivate",
        "com.microsoft.edgemac.Beta": "--inprivate",
        "company.thebrowser.Browser": "--incognito", // Arc
        "org.chromium.Chromium": "--incognito",
        "org.mozilla.firefox": "-private-window",
        "org.mozilla.firefoxdeveloperedition": "-private-window",
    ]

    func detectBrowsers() -> [Browser] {
        guard let url = URL(string: "https://example.com") else { return [] }
        guard let appURLs = LSCopyApplicationURLsForURL(url as CFURL, .viewer)?.takeRetainedValue() as? [URL] else {
            return []
        }

        var seen = Set<String>()
        var browsers: [Browser] = []

        for appURL in appURLs {
            guard let bundle = Bundle(url: appURL),
                  let bundleID = bundle.bundleIdentifier,
                  !seen.contains(bundleID),
                  bundleID != "com.hop.browserPicker" // exclude ourselves
            else { continue }

            seen.insert(bundleID)

            let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? appURL.deletingPathExtension().lastPathComponent

            let privateFlag = Self.privateFlagMap[bundleID]

            browsers.append(Browser(
                id: bundleID,
                name: name,
                path: appURL,
                privateFlag: privateFlag
            ))
        }

        return browsers
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ~/hop && swift test --filter BrowserDetectorTests 2>&1`
Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/Hop/BrowserDetector.swift Tests/HopTests/BrowserDetectorTests.swift
git commit -m "feat: browser detection with private mode flags"
```

---

## Task 3: Rule Engine

**Files:**
- Create: `Sources/Hop/RuleEngine.swift`
- Create: `Tests/HopTests/RuleEngineTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// Tests/HopTests/RuleEngineTests.swift
import XCTest
@testable import Hop

final class RuleEngineTests: XCTestCase {

    let chromeBeta = "com.google.Chrome.beta"

    // MARK: - Domain matching

    func testMatchesExactDomain() {
        let rules = [Rule(pattern: "example.com", browserID: chromeBeta)]
        let engine = RuleEngine(rules: rules)
        let result = engine.evaluate(url: URL(string: "https://example.com/dashboard")!)
        XCTAssertEqual(result, chromeBeta)
    }

    func testMatchesSubdomain() {
        let rules = [Rule(pattern: "example.com", browserID: chromeBeta)]
        let engine = RuleEngine(rules: rules)
        let result = engine.evaluate(url: URL(string: "https://ci.example.com/job/123")!)
        XCTAssertEqual(result, chromeBeta)
    }

    func testNoMatchReturnNil() {
        let rules = [Rule(pattern: "example.com", browserID: chromeBeta)]
        let engine = RuleEngine(rules: rules)
        let result = engine.evaluate(url: URL(string: "https://google.com")!)
        XCTAssertNil(result)
    }

    // MARK: - Path glob matching

    func testMatchesDomainWithPathGlob() {
        let rules = [Rule(pattern: "github.com/my-org/*", browserID: chromeBeta)]
        let engine = RuleEngine(rules: rules)
        let result = engine.evaluate(url: URL(string: "https://github.com/my-org/repo/pulls")!)
        XCTAssertEqual(result, chromeBeta)
    }

    func testPathGlobDoesNotMatchOtherPaths() {
        let rules = [Rule(pattern: "github.com/my-org/*", browserID: chromeBeta)]
        let engine = RuleEngine(rules: rules)
        let result = engine.evaluate(url: URL(string: "https://github.com/other-org/repo")!)
        XCTAssertNil(result)
    }

    // MARK: - Rule ordering and enabled

    func testFirstMatchWins() {
        let rules = [
            Rule(pattern: "slack.com", browserID: "com.brave.Browser.beta"),
            Rule(pattern: "slack.com", browserID: chromeBeta),
        ]
        let engine = RuleEngine(rules: rules)
        let result = engine.evaluate(url: URL(string: "https://slack.com/channel")!)
        XCTAssertEqual(result, "com.brave.Browser.beta")
    }

    func testDisabledRuleSkipped() {
        let rules = [
            Rule(pattern: "slack.com", browserID: "com.brave.Browser.beta", isEnabled: false),
            Rule(pattern: "slack.com", browserID: chromeBeta),
        ]
        let engine = RuleEngine(rules: rules)
        let result = engine.evaluate(url: URL(string: "https://slack.com/channel")!)
        XCTAssertEqual(result, chromeBeta)
    }

    func testEmptyRulesReturnNil() {
        let engine = RuleEngine(rules: [])
        let result = engine.evaluate(url: URL(string: "https://anything.com")!)
        XCTAssertNil(result)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd ~/hop && swift test --filter RuleEngineTests 2>&1`
Expected: FAIL — `RuleEngine` not found.

- [ ] **Step 3: Implement RuleEngine**

```swift
// Sources/Hop/RuleEngine.swift
import Foundation

final class RuleEngine {
    private let rules: [Rule]

    init(rules: [Rule]) {
        self.rules = rules
    }

    /// Evaluate URL against rules. Returns target browser bundle ID or nil.
    func evaluate(url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        let path = url.path.lowercased()

        for rule in rules where rule.isEnabled {
            if matches(host: host, path: path, pattern: rule.pattern.lowercased()) {
                return rule.browserID
            }
        }
        return nil
    }

    private func matches(host: String, path: String, pattern: String) -> Bool {
        // Split pattern into domain part and optional path glob
        let parts = pattern.split(separator: "/", maxSplits: 1)
        let domainPattern = String(parts[0])
        let pathPattern = parts.count > 1 ? "/" + String(parts[1]) : nil

        // Domain match: exact or subdomain (host ends with .domain or equals domain)
        let domainMatches = host == domainPattern || host.hasSuffix("." + domainPattern)
        guard domainMatches else { return false }

        // If no path pattern, domain match is enough
        guard let pathPattern else { return true }

        // Path glob: convert simple glob (* matches anything) to check
        return pathGlobMatch(path: path, pattern: pathPattern)
    }

    private func pathGlobMatch(path: String, pattern: String) -> Bool {
        // Convert glob pattern to regex:
        // * matches one or more path segments
        // Everything else is literal
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
        let regexPattern = "^" + escaped.replacingOccurrences(of: "\\*", with: ".*") + ".*$"

        guard let regex = try? NSRegularExpression(pattern: regexPattern) else { return false }
        let range = NSRange(path.startIndex..., in: path)
        return regex.firstMatch(in: path, range: range) != nil
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ~/hop && swift test --filter RuleEngineTests 2>&1`
Expected: All 8 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/Hop/RuleEngine.swift Tests/HopTests/RuleEngineTests.swift
git commit -m "feat: rule engine with domain and path glob matching"
```

---

## Task 4: Data Persistence (RuleStore + HistoryStore)

**Files:**
- Create: `Sources/Hop/RuleStore.swift`
- Create: `Sources/Hop/HistoryStore.swift`
- Create: `Tests/HopTests/RuleStoreTests.swift`
- Create: `Tests/HopTests/HistoryStoreTests.swift`

- [ ] **Step 1: Write failing tests for RuleStore**

```swift
// Tests/HopTests/RuleStoreTests.swift
import XCTest
@testable import Hop

final class RuleStoreTests: XCTestCase {
    var tempDir: URL!
    var store: RuleStore!

    override func setUp() {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = RuleStore(directory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testEmptyByDefault() {
        XCTAssertTrue(store.rules.isEmpty)
    }

    func testAddAndRetrieveRule() {
        let rule = Rule(pattern: "example.com", browserID: "com.google.Chrome")
        store.add(rule)
        XCTAssertEqual(store.rules.count, 1)
        XCTAssertEqual(store.rules[0].pattern, "example.com")
    }

    func testPersistsToDisk() {
        store.add(Rule(pattern: "example.com", browserID: "com.google.Chrome"))
        let store2 = RuleStore(directory: tempDir)
        XCTAssertEqual(store2.rules.count, 1)
        XCTAssertEqual(store2.rules[0].pattern, "example.com")
    }

    func testDeleteRule() {
        let rule = Rule(pattern: "example.com", browserID: "com.google.Chrome")
        store.add(rule)
        store.delete(rule.id)
        XCTAssertTrue(store.rules.isEmpty)
    }

    func testUpdateRule() {
        var rule = Rule(pattern: "example.com", browserID: "com.google.Chrome")
        store.add(rule)
        rule.pattern = "updated.com"
        store.update(rule)
        XCTAssertEqual(store.rules[0].pattern, "updated.com")
    }

    func testMoveRule() {
        store.add(Rule(pattern: "first.com", browserID: "a"))
        store.add(Rule(pattern: "second.com", browserID: "b"))
        store.move(from: IndexSet(integer: 1), to: 0)
        XCTAssertEqual(store.rules[0].pattern, "second.com")
    }
}
```

- [ ] **Step 2: Write failing tests for HistoryStore**

```swift
// Tests/HopTests/HistoryStoreTests.swift
import XCTest
@testable import Hop

final class HistoryStoreTests: XCTestCase {
    var tempDir: URL!
    var store: HistoryStore!

    override func setUp() {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = HistoryStore(directory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testEmptyByDefault() {
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testAddEntry() {
        store.add(url: "https://example.com", browserID: "com.google.Chrome")
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries[0].url, "https://example.com")
    }

    func testLimitedTo50Entries() {
        for i in 0..<60 {
            store.add(url: "https://example.com/\(i)", browserID: "com.google.Chrome")
        }
        XCTAssertEqual(store.entries.count, 50)
        // Most recent should be first
        XCTAssertEqual(store.entries[0].url, "https://example.com/59")
    }

    func testPersistsToDisk() {
        store.add(url: "https://example.com", browserID: "com.google.Chrome")
        let store2 = HistoryStore(directory: tempDir)
        XCTAssertEqual(store2.entries.count, 1)
    }

    func testClearAll() {
        store.add(url: "https://example.com", browserID: "com.google.Chrome")
        store.clearAll()
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testRecentReturnsLastN() {
        for i in 0..<20 {
            store.add(url: "https://example.com/\(i)", browserID: "com.google.Chrome")
        }
        let recent = store.recent(10)
        XCTAssertEqual(recent.count, 10)
        XCTAssertEqual(recent[0].url, "https://example.com/19")
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd ~/hop && swift test --filter "RuleStoreTests|HistoryStoreTests" 2>&1`
Expected: FAIL — classes not found.

- [ ] **Step 4: Implement RuleStore**

```swift
// Sources/Hop/RuleStore.swift
import Foundation

final class RuleStore: ObservableObject {
    @Published private(set) var rules: [Rule] = []
    private let fileURL: URL

    init(directory: URL) {
        self.fileURL = directory.appendingPathComponent("rules.json")
        self.rules = Self.load(from: fileURL)
    }

    func add(_ rule: Rule) {
        rules.append(rule)
        save()
    }

    func delete(_ id: UUID) {
        rules.removeAll { $0.id == id }
        save()
    }

    func update(_ rule: Rule) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index] = rule
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        rules.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func replaceAll(_ newRules: [Rule]) {
        rules = newRules
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(rules) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func load(from url: URL) -> [Rule] {
        guard let data = try? Data(contentsOf: url),
              let rules = try? JSONDecoder().decode([Rule].self, from: data)
        else { return [] }
        return rules
    }
}
```

- [ ] **Step 5: Implement HistoryStore**

```swift
// Sources/Hop/HistoryStore.swift
import Foundation

final class HistoryStore: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    private let fileURL: URL
    private let maxEntries = 50

    init(directory: URL) {
        self.fileURL = directory.appendingPathComponent("history.json")
        self.entries = Self.load(from: fileURL)
    }

    func add(url: String, browserID: String) {
        let entry = HistoryEntry(url: url, browserID: browserID)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        save()
    }

    func recent(_ count: Int) -> [HistoryEntry] {
        Array(entries.prefix(count))
    }

    func clearAll() {
        entries.removeAll()
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func load(from url: URL) -> [HistoryEntry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([HistoryEntry].self, from: data)) ?? []
    }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd ~/hop && swift test --filter "RuleStoreTests|HistoryStoreTests" 2>&1`
Expected: All 12 tests PASS.

- [ ] **Step 7: Commit**

```bash
git add Sources/Hop/RuleStore.swift Sources/Hop/HistoryStore.swift Tests/HopTests/RuleStoreTests.swift Tests/HopTests/HistoryStoreTests.swift
git commit -m "feat: rule and history persistence with JSON storage"
```

---

## Task 5: Browser Launcher

**Files:**
- Create: `Sources/Hop/BrowserLauncher.swift`
- Create: `Tests/HopTests/BrowserLauncherTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// Tests/HopTests/BrowserLauncherTests.swift
import XCTest
@testable import Hop

final class BrowserLauncherTests: XCTestCase {

    func testBuildPrivateArgs_Chrome() {
        let args = BrowserLauncher.privateArgs(
            for: URL(string: "https://example.com")!,
            flag: "--incognito"
        )
        XCTAssertEqual(args, ["--incognito", "https://example.com"])
    }

    func testBuildPrivateArgs_Firefox() {
        let args = BrowserLauncher.privateArgs(
            for: URL(string: "https://example.com")!,
            flag: "-private-window"
        )
        XCTAssertEqual(args, ["-private-window", "https://example.com"])
    }

    func testBuildPrivateArgs_NoFlag() {
        let args = BrowserLauncher.privateArgs(
            for: URL(string: "https://example.com")!,
            flag: nil
        )
        XCTAssertNil(args, "Should return nil when browser has no private flag")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd ~/hop && swift test --filter BrowserLauncherTests 2>&1`
Expected: FAIL — `BrowserLauncher` not found.

- [ ] **Step 3: Implement BrowserLauncher**

```swift
// Sources/Hop/BrowserLauncher.swift
import AppKit

final class BrowserLauncher {

    /// Open URL in the specified browser normally.
    static func open(url: URL, in browser: Browser) {
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: browser.path,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    /// Open URL in the specified browser in private/incognito mode.
    /// Falls back to normal open if browser has no private flag.
    static func openPrivate(url: URL, in browser: Browser) {
        guard let flag = browser.privateFlag else {
            open(url: url, in: browser)
            return
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", browser.path.path, url.absoluteString, "--args", flag]
        try? task.run()
    }

    /// Build the private-mode argument list (for testing).
    static func privateArgs(for url: URL, flag: String?) -> [String]? {
        guard let flag else { return nil }
        return [flag, url.absoluteString]
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ~/hop && swift test --filter BrowserLauncherTests 2>&1`
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/Hop/BrowserLauncher.swift Tests/HopTests/BrowserLauncherTests.swift
git commit -m "feat: browser launcher with private/incognito support"
```

---

## Task 6: URL Router

**Files:**
- Create: `Sources/Hop/URLRouter.swift`
- Create: `Tests/HopTests/URLRouterTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// Tests/HopTests/URLRouterTests.swift
import XCTest
@testable import Hop

final class URLRouterTests: XCTestCase {

    func testRuleMatchReturnsAutoOpen() {
        let rules = [Rule(pattern: "example.com", browserID: "com.google.Chrome.beta")]
        let router = URLRouter(rules: rules)
        let result = router.route(url: URL(string: "https://example.com/test")!)
        if case .autoOpen(let browserID) = result {
            XCTAssertEqual(browserID, "com.google.Chrome.beta")
        } else {
            XCTFail("Expected autoOpen, got \(result)")
        }
    }

    func testNoRuleMatchReturnsShowPicker() {
        let rules = [Rule(pattern: "example.com", browserID: "com.google.Chrome.beta")]
        let router = URLRouter(rules: rules)
        let result = router.route(url: URL(string: "https://google.com")!)
        if case .showPicker = result {
            // pass
        } else {
            XCTFail("Expected showPicker, got \(result)")
        }
    }

    func testEmptyRulesReturnsShowPicker() {
        let router = URLRouter(rules: [])
        let result = router.route(url: URL(string: "https://anything.com")!)
        if case .showPicker = result {
            // pass
        } else {
            XCTFail("Expected showPicker")
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd ~/hop && swift test --filter URLRouterTests 2>&1`
Expected: FAIL — `URLRouter` not found.

- [ ] **Step 3: Implement URLRouter**

```swift
// Sources/Hop/URLRouter.swift
import Foundation

enum RouteResult {
    case autoOpen(browserID: String)
    case showPicker
}

final class URLRouter {
    private let ruleEngine: RuleEngine

    init(rules: [Rule]) {
        self.ruleEngine = RuleEngine(rules: rules)
    }

    func route(url: URL) -> RouteResult {
        if let browserID = ruleEngine.evaluate(url: url) {
            return .autoOpen(browserID: browserID)
        }
        return .showPicker
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ~/hop && swift test --filter URLRouterTests 2>&1`
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/Hop/URLRouter.swift Tests/HopTests/URLRouterTests.swift
git commit -m "feat: URL router with rule-based routing decisions"
```

---

## Task 7: Picker Panel (AppKit)

**Files:**
- Create: `Sources/Hop/PickerPanel.swift`
- Create: `Sources/Hop/PickerViewController.swift`

This task has no automated tests since it's pure UI (NSPanel + keyboard handling). We'll test it manually in Task 10.

- [ ] **Step 1: Create PickerPanel (NSPanel subclass)**

```swift
// Sources/Hop/PickerPanel.swift
import AppKit

final class PickerPanel: NSPanel {
    private var onDismiss: (() -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .popUpMenu
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
    }

    func showPicker(
        at point: NSPoint,
        url: URL,
        browsers: [Browser],
        onSelect: @escaping (Browser, Bool) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onDismiss = onDismiss

        let viewController = PickerViewController(
            url: url,
            browsers: browsers,
            onSelect: { [weak self] browser, isPrivate in
                self?.close()
                onSelect(browser, isPrivate)
            },
            onCancel: { [weak self] in
                self?.close()
                onDismiss()
            }
        )

        contentViewController = viewController

        // Size to fit content
        let browserCount = browsers.count
        let width: CGFloat = 320
        let height: CGFloat = CGFloat(70 + browserCount * 52)
        let frame = NSRect(
            x: point.x,
            y: point.y - height,
            width: width,
            height: height
        )
        setFrame(frame, display: true)

        // Ensure panel stays on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            var adjustedFrame = frame
            if adjustedFrame.maxX > screenFrame.maxX {
                adjustedFrame.origin.x = screenFrame.maxX - width
            }
            if adjustedFrame.minY < screenFrame.minY {
                adjustedFrame.origin.y = screenFrame.minY
            }
            if adjustedFrame.minX < screenFrame.minX {
                adjustedFrame.origin.x = screenFrame.minX
            }
            setFrame(adjustedFrame, display: true)
        }

        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    override func resignKey() {
        super.resignKey()
        close()
        onDismiss?()
    }

    override func cancelOperation(_ sender: Any?) {
        close()
        onDismiss?()
    }
}
```

- [ ] **Step 2: Create PickerViewController**

```swift
// Sources/Hop/PickerViewController.swift
import AppKit
import SwiftUI

final class PickerViewController: NSHostingController<PickerContentView> {

    init(
        url: URL,
        browsers: [Browser],
        onSelect: @escaping (Browser, Bool) -> Void,
        onCancel: @escaping () -> Void
    ) {
        let view = PickerContentView(
            url: url,
            browsers: browsers,
            onSelect: onSelect,
            onCancel: onCancel
        )
        super.init(rootView: view)
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
}

struct PickerContentView: View {
    let url: URL
    let browsers: [Browser]
    let onSelect: (Browser, Bool) -> Void
    let onCancel: () -> Void

    @State private var hoveredIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // URL display
            Text(url.absoluteString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider().padding(.horizontal, 8)

            // Browser list
            ForEach(Array(browsers.enumerated()), id: \.element.id) { index, browser in
                BrowserRowView(
                    browser: browser,
                    index: index + 1,
                    isHovered: hoveredIndex == index,
                    onSelect: onSelect
                )
                .onHover { isHovered in
                    hoveredIndex = isHovered ? index : nil
                }
            }

            Divider().padding(.horizontal, 8)

            // Hint
            Text("⌥ Option + click for private window  ·  Esc to cancel")
                .font(.system(size: 10))
                .foregroundColor(.tertiaryLabel)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .frame(width: 320)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onKeyPress(.escape) {
            onCancel()
            return .handled
        }
        .onKeyPress(characters: .decimalDigits) { press in
            guard let digit = Int(press.characters), digit >= 1, digit <= browsers.count else {
                return .ignored
            }
            let isPrivate = press.modifiers.contains(.option)
            onSelect(browsers[digit - 1], isPrivate)
            return .handled
        }
    }
}

struct BrowserRowView: View {
    let browser: Browser
    let index: Int
    let isHovered: Bool
    let onSelect: (Browser, Bool) -> Void

    var body: some View {
        Button {
            let isPrivate = NSEvent.modifierFlags.contains(.option)
            onSelect(browser, isPrivate)
        } label: {
            HStack(spacing: 10) {
                // Number badge
                Text("\(index)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(width: 18)

                // Browser icon
                if let icon = browser.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "globe")
                        .frame(width: 28, height: 28)
                }

                // Browser name
                Text(browser.name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)

                Spacer()

                // Private mode indicator
                if browser.privateFlag != nil {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 10))
                        .foregroundColor(.tertiaryLabel)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}
```

- [ ] **Step 3: Build to verify compilation**

Run: `cd ~/hop && swift build 2>&1`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add Sources/Hop/PickerPanel.swift Sources/Hop/PickerViewController.swift
git commit -m "feat: floating picker panel with keyboard and mouse selection"
```

---

## Task 8: Velja Migrator

**Files:**
- Create: `Sources/Hop/VeljaMigrator.swift`
- Create: `Tests/HopTests/VeljaMigratorTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// Tests/HopTests/VeljaMigratorTests.swift
import XCTest
@testable import Hop

final class VeljaMigratorTests: XCTestCase {

    func testParseVeljaRuleJSON() {
        let veljaJSON = """
        {"browser":"com.google.Chrome.beta","forceNewWindow":false,"id":"6E05E113-F2A4-4E98-A8B5-D47FB67DED06","isEnabled":true,"isTransformScriptEnabled":false,"matchers":[{"fixture":"https://ci.example.com","id":"16CD4262-6242-4FC4-A998-2D081B50E7E9","kind":"hostSuffix","pattern":"example.com"}],"onlyFromAirdrop":false,"openInBackground":false,"runAfterBuiltinRules":false,"sourceApps":[],"title":"example.com → Chrome Beta","transformScript":"","transformTestURL":""}
        """
        let rules = VeljaMigrator.parseVeljaRules(from: [veljaJSON])
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules[0].pattern, "example.com")
        XCTAssertEqual(rules[0].browserID, "com.google.Chrome.beta")
        XCTAssertTrue(rules[0].isEnabled)
    }

    func testParseMultipleVeljaRules() {
        let rules_json = [
            """
            {"browser":"com.google.Chrome.beta","isEnabled":true,"matchers":[{"kind":"hostSuffix","pattern":"example.com"}],"title":"test1"}
            """,
            """
            {"browser":"com.google.Chrome.beta","isEnabled":true,"matchers":[{"kind":"hostSuffix","pattern":"slack.com"}],"title":"test2"}
            """,
        ]
        let rules = VeljaMigrator.parseVeljaRules(from: rules_json)
        XCTAssertEqual(rules.count, 2)
        XCTAssertEqual(rules[0].pattern, "example.com")
        XCTAssertEqual(rules[1].pattern, "slack.com")
    }

    func testDisabledVeljaRuleStaysDisabled() {
        let json = """
        {"browser":"com.google.Chrome.beta","isEnabled":false,"matchers":[{"kind":"hostSuffix","pattern":"example.com"}],"title":"test"}
        """
        let rules = VeljaMigrator.parseVeljaRules(from: [json])
        XCTAssertEqual(rules.count, 1)
        XCTAssertFalse(rules[0].isEnabled)
    }

    func testHasVeljaDataReturnsFalseWhenNoData() {
        XCTAssertFalse(VeljaMigrator.hasVeljaData(in: UserDefaults(suiteName: UUID().uuidString)!))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd ~/hop && swift test --filter VeljaMigratorTests 2>&1`
Expected: FAIL — `VeljaMigrator` not found.

- [ ] **Step 3: Implement VeljaMigrator**

```swift
// Sources/Hop/VeljaMigrator.swift
import Foundation

enum VeljaMigrator {

    /// Check if Velja rules exist in its UserDefaults
    static func hasVeljaData(in defaults: UserDefaults = UserDefaults(suiteName: "com.sindresorhus.Velja") ?? .standard) -> Bool {
        let rules = defaults.array(forKey: "rules") as? [String] ?? []
        return !rules.isEmpty
    }

    /// Read Velja rules from UserDefaults and convert to Hop rules
    static func importFromVelja(defaults: UserDefaults = UserDefaults(suiteName: "com.sindresorhus.Velja") ?? .standard) -> [Rule] {
        let ruleStrings = defaults.array(forKey: "rules") as? [String] ?? []
        return parseVeljaRules(from: ruleStrings)
    }

    /// Parse Velja rule JSON strings into Hop Rule objects
    static func parseVeljaRules(from jsonStrings: [String]) -> [Rule] {
        var rules: [Rule] = []

        for jsonString in jsonStrings {
            guard let data = jsonString.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let browserID = dict["browser"] as? String,
                  let matchers = dict["matchers"] as? [[String: Any]],
                  let firstMatcher = matchers.first,
                  let pattern = firstMatcher["pattern"] as? String
            else { continue }

            let isEnabled = dict["isEnabled"] as? Bool ?? true

            rules.append(Rule(
                pattern: pattern,
                browserID: browserID,
                isEnabled: isEnabled
            ))
        }

        return rules
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ~/hop && swift test --filter VeljaMigratorTests 2>&1`
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/Hop/VeljaMigrator.swift Tests/HopTests/VeljaMigratorTests.swift
git commit -m "feat: Velja rule migration parser"
```

---

## Task 9: Settings UI

**Files:**
- Create: `Sources/Hop/Settings/SettingsView.swift`
- Create: `Sources/Hop/Settings/RulesSettingsView.swift`
- Create: `Sources/Hop/Settings/BrowsersSettingsView.swift`
- Create: `Sources/Hop/Settings/HistorySettingsView.swift`
- Create: `Sources/Hop/Settings/GeneralSettingsView.swift`

No automated tests for settings UI. Manual verification in Task 10.

- [ ] **Step 1: Create SettingsView container**

```swift
// Sources/Hop/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var ruleStore: RuleStore
    @ObservedObject var historyStore: HistoryStore
    @Binding var browsers: [Browser]
    let onRedetectBrowsers: () -> Void
    let onImportVelja: () -> Void

    var body: some View {
        TabView {
            RulesSettingsView(ruleStore: ruleStore, browsers: browsers)
                .tabItem { Label("Rules", systemImage: "list.bullet") }

            BrowsersSettingsView(browsers: $browsers, onRedetect: onRedetectBrowsers)
                .tabItem { Label("Browsers", systemImage: "globe") }

            HistorySettingsView(historyStore: historyStore, browsers: browsers)
                .tabItem { Label("History", systemImage: "clock") }

            GeneralSettingsView(onImportVelja: onImportVelja)
                .tabItem { Label("General", systemImage: "gear") }
        }
        .frame(width: 500, height: 400)
    }
}
```

- [ ] **Step 2: Create RulesSettingsView**

```swift
// Sources/Hop/Settings/RulesSettingsView.swift
import SwiftUI

struct RulesSettingsView: View {
    @ObservedObject var ruleStore: RuleStore
    let browsers: [Browser]
    @State private var showAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(ruleStore.rules) { rule in
                    RuleRowView(rule: rule, browsers: browsers) { updated in
                        ruleStore.update(updated)
                    }
                }
                .onMove { source, destination in
                    ruleStore.move(from: source, to: destination)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        ruleStore.delete(ruleStore.rules[index].id)
                    }
                }
            }

            Divider()

            HStack {
                Button(action: { showAddSheet = true }) {
                    Label("Add Rule", systemImage: "plus")
                }
                Spacer()
                Text("\(ruleStore.rules.count) rules")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(8)
        }
        .sheet(isPresented: $showAddSheet) {
            AddRuleSheet(browsers: browsers) { newRule in
                ruleStore.add(newRule)
            }
        }
    }
}

struct RuleRowView: View {
    let rule: Rule
    let browsers: [Browser]
    let onUpdate: (Rule) -> Void

    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { enabled in
                    var updated = rule
                    updated.isEnabled = enabled
                    onUpdate(updated)
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            VStack(alignment: .leading) {
                Text(rule.pattern)
                    .font(.system(size: 13, design: .monospaced))
                if let browser = browsers.first(where: { $0.id == rule.browserID }) {
                    Text(browser.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}

struct AddRuleSheet: View {
    let browsers: [Browser]
    let onAdd: (Rule) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var pattern = ""
    @State private var selectedBrowserID = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Rule").font(.headline)

            TextField("Pattern (e.g. example.com)", text: $pattern)
                .textFieldStyle(.roundedBorder)

            Picker("Open in:", selection: $selectedBrowserID) {
                ForEach(browsers) { browser in
                    Text(browser.name).tag(browser.id)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") {
                    guard !pattern.isEmpty, !selectedBrowserID.isEmpty else { return }
                    onAdd(Rule(pattern: pattern, browserID: selectedBrowserID))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(pattern.isEmpty || selectedBrowserID.isEmpty)
            }
        }
        .padding()
        .frame(width: 350)
        .onAppear {
            selectedBrowserID = browsers.first?.id ?? ""
        }
    }
}
```

- [ ] **Step 3: Create BrowsersSettingsView**

```swift
// Sources/Hop/Settings/BrowsersSettingsView.swift
import SwiftUI

struct BrowsersSettingsView: View {
    @Binding var browsers: [Browser]
    let onRedetect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(Array(browsers.enumerated()), id: \.element.id) { index, browser in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(width: 20)

                        if let icon = browser.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }

                        VStack(alignment: .leading) {
                            Text(browser.name)
                                .font(.system(size: 13))
                            Text(browser.id)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if browser.privateFlag != nil {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .help("Private mode supported")
                        }
                    }
                }
                .onMove { source, destination in
                    browsers.move(fromOffsets: source, toOffset: destination)
                }
            }

            Divider()

            HStack {
                Button(action: onRedetect) {
                    Label("Re-detect Browsers", systemImage: "arrow.clockwise")
                }
                Spacer()
                Text("Drag to reorder. Order sets keyboard shortcuts in picker.")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(8)
        }
    }
}
```

- [ ] **Step 4: Create HistorySettingsView**

```swift
// Sources/Hop/Settings/HistorySettingsView.swift
import SwiftUI

struct HistorySettingsView: View {
    @ObservedObject var historyStore: HistoryStore
    let browsers: [Browser]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(historyStore.entries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.url)
                                .font(.system(size: 12, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            HStack(spacing: 4) {
                                if let browser = browsers.first(where: { $0.id == entry.browserID }) {
                                    Text(browser.name)
                                }
                                Text("·")
                                Text(entry.timestamp, style: .relative)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }

            Divider()

            HStack {
                Button(role: .destructive, action: { historyStore.clearAll() }) {
                    Label("Clear All", systemImage: "trash")
                }
                Spacer()
                Text("\(historyStore.entries.count) entries")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(8)
        }
    }
}
```

- [ ] **Step 5: Create GeneralSettingsView**

```swift
// Sources/Hop/Settings/GeneralSettingsView.swift
import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    let onImportVelja: () -> Void

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        if newValue {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }
            }

            Section("Migration") {
                Button("Import Rules from Velja") {
                    onImportVelja()
                }
                .disabled(!VeljaMigrator.hasVeljaData())
                Text("Reads existing Velja rules and adds them to Hop.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("About") {
                Text("Hop v1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("A lightweight browser picker for macOS.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
```

- [ ] **Step 6: Create Settings directory and build**

Run: `mkdir -p ~/hop/Sources/Hop/Settings && cd ~/hop && swift build 2>&1`
Expected: Build succeeds.

- [ ] **Step 7: Commit**

```bash
git add Sources/Hop/Settings/
git commit -m "feat: settings UI with rules, browsers, history, and general tabs"
```

---

## Task 10: Wire Everything Together in HopApp

**Files:**
- Modify: `Sources/Hop/HopApp.swift` (replace stub with full implementation)

- [ ] **Step 1: Replace HopApp.swift with full implementation**

```swift
// Sources/Hop/HopApp.swift
import SwiftUI
import AppKit

@main
struct HopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                ruleStore: appDelegate.ruleStore,
                historyStore: appDelegate.historyStore,
                browsers: Binding(
                    get: { appDelegate.browsers },
                    set: { appDelegate.browsers = $0 }
                ),
                onRedetectBrowsers: { appDelegate.redetectBrowsers() },
                onImportVelja: { appDelegate.importVeljaRules() }
            )
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    let ruleStore: RuleStore
    let historyStore: HistoryStore
    private let browserDetector = BrowserDetector()
    private let pickerPanel = PickerPanel()
    @Published var browsers: [Browser] = []
    @Published var isEnabled = true

    override init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Hop")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        self.ruleStore = RuleStore(directory: appSupport)
        self.historyStore = HistoryStore(directory: appSupport)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        redetectBrowsers()
        offerVeljaMigration()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard isEnabled else {
            // When disabled, open in first detected browser
            if let browser = browsers.first, let url = urls.first {
                BrowserLauncher.open(url: url, in: browser)
            }
            return
        }

        for url in urls {
            handleURL(url)
        }
    }

    // MARK: - URL Handling

    private func handleURL(_ url: URL) {
        let router = URLRouter(rules: ruleStore.rules)
        let result = router.route(url: url)

        switch result {
        case .autoOpen(let browserID):
            guard let browser = browsers.first(where: { $0.id == browserID }) else {
                showPicker(for: url)
                return
            }
            BrowserLauncher.open(url: url, in: browser)
            historyStore.add(url: url.absoluteString, browserID: browserID)

        case .showPicker:
            showPicker(for: url)
        }
    }

    private func showPicker(for url: URL) {
        let mouseLocation = NSEvent.mouseLocation
        pickerPanel.showPicker(
            at: mouseLocation,
            url: url,
            browsers: browsers,
            onSelect: { [weak self] browser, isPrivate in
                if isPrivate {
                    BrowserLauncher.openPrivate(url: url, in: browser)
                    // Do NOT add to history for private mode
                } else {
                    BrowserLauncher.open(url: url, in: browser)
                    self?.historyStore.add(url: url.absoluteString, browserID: browser.id)
                }
            },
            onDismiss: { /* nothing to do */ }
        )
    }

    // MARK: - Menu Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.trianglehead.branch", accessibilityDescription: "Hop")
        }
        updateMenu()
    }

    func updateMenu() {
        let menu = NSMenu()

        // Enabled toggle
        let toggleItem = NSMenuItem(
            title: isEnabled ? "Enabled" : "Disabled",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = isEnabled ? .on : .off
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Recent history
        let recent = historyStore.recent(10)
        if recent.isEmpty {
            let emptyItem = NSMenuItem(title: "No recent URLs", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for entry in recent {
                let displayURL = entry.url.count > 50
                    ? String(entry.url.prefix(50)) + "..."
                    : entry.url
                let browserName = browsers.first(where: { $0.id == entry.browserID })?.name ?? "Unknown"
                let item = NSMenuItem(
                    title: "\(displayURL) → \(browserName)",
                    action: #selector(reopenHistoryItem(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = entry
                item.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "Quit Hop", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        updateMenu()
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func reopenHistoryItem(_ sender: NSMenuItem) {
        guard let entry = sender.representedObject as? HistoryEntry,
              let url = URL(string: entry.url),
              let browser = browsers.first(where: { $0.id == entry.browserID })
        else { return }
        BrowserLauncher.open(url: url, in: browser)
    }

    // MARK: - Browsers

    func redetectBrowsers() {
        browsers = browserDetector.detectBrowsers()
    }

    // MARK: - Velja Migration

    func importVeljaRules() {
        let imported = VeljaMigrator.importFromVelja()
        for rule in imported {
            ruleStore.add(rule)
        }
    }

    private func offerVeljaMigration() {
        guard VeljaMigrator.hasVeljaData(),
              ruleStore.rules.isEmpty else { return }

        let alert = NSAlert()
        alert.messageText = "Import Velja Rules?"
        alert.informativeText = "Velja rules were detected. Would you like to import them into Hop?"
        alert.addButton(withTitle: "Import")
        alert.addButton(withTitle: "Skip")

        if alert.runModal() == .alertFirstButtonReturn {
            importVeljaRules()
        }
    }
}
```

- [ ] **Step 2: Build the full app**

Run: `cd ~/hop && swift build 2>&1`
Expected: Build succeeds.

- [ ] **Step 3: Run all tests**

Run: `cd ~/hop && swift test 2>&1`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add Sources/Hop/HopApp.swift
git commit -m "feat: wire all components into working app with menu bar and URL handling"
```

---

## Task 11: Build, Package, and Manual Test

**Files:** No new files. This is integration and packaging.

- [ ] **Step 1: Build release binary**

Run: `cd ~/hop && swift build -c release 2>&1`
Expected: Build succeeds.

- [ ] **Step 2: Create app bundle**

```bash
cd ~/hop

APP_DIR="Hop.app/Contents/MacOS"
mkdir -p "$APP_DIR"
mkdir -p "Hop.app/Contents/Resources"

# Copy binary
cp .build/release/Hop "$APP_DIR/Hop"

# Copy Info.plist
cp Sources/Hop/Resources/Info.plist Hop.app/Contents/Info.plist

# Create PkgInfo
echo -n "APPL????" > Hop.app/Contents/PkgInfo

echo "App bundle created at Hop.app"
```

- [ ] **Step 3: Install to /Applications**

```bash
cp -r ~/hop/Hop.app /Applications/Hop.app
echo "Installed to /Applications/Hop.app"
```

- [ ] **Step 4: Launch and manual test**

```bash
open /Applications/Hop.app
```

Manual test checklist:
- [ ] Menu bar icon appears
- [ ] Click menu bar icon → dropdown shows "No recent URLs", Settings, Quit
- [ ] Open Settings → verify all 4 tabs render
- [ ] Browsers tab shows detected browsers
- [ ] Set Hop as default browser: System Settings → Desktop & Dock → Default web browser → Hop
- [ ] Click a link in another app (e.g. Slack, Terminal: `open https://example.com`)
- [ ] Picker panel appears near cursor
- [ ] Click a browser → URL opens in that browser
- [ ] Press number key → URL opens in corresponding browser
- [ ] Hold Option + click → URL opens in private window
- [ ] Add a rule in Settings (e.g. `example.com` → Chrome Beta)
- [ ] Click a matching link → auto-opens without picker
- [ ] Check history in menu bar and Settings → History tab
- [ ] Verify incognito URLs are NOT in history

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: app bundle packaging and release build"
```

---

## Task 12: Cleanup - Remove Velja and Browserosaurus

- [ ] **Step 1: Remove old browser pickers**

```bash
# Quit Velja
osascript -e 'quit app "Velja"' 2>/dev/null

# Remove Browserosaurus
brew uninstall browserosaurus 2>/dev/null

# Velja can be removed from /Applications if desired
# (may need sudo depending on how it was installed)
```

- [ ] **Step 2: Verify Hop is default browser**

Open System Settings → Desktop & Dock → Default web browser → confirm it says "Hop".

- [ ] **Step 3: Final commit**

```bash
cd ~/hop
git log --oneline
```

Expected commit history:
```
feat: app bundle packaging and release build
feat: wire all components into working app with menu bar and URL handling
feat: settings UI with rules, browsers, history, and general tabs
feat: Velja rule migration parser
feat: floating picker panel with keyboard and mouse selection
feat: URL router with rule-based routing decisions
feat: browser launcher with private/incognito support
feat: rule and history persistence with JSON storage
feat: rule engine with domain and path glob matching
feat: browser detection with private mode flags
feat: project scaffold with models and Info.plist
```

---

Plan complete and saved to `docs/plans/2026-03-29-hop-implementation.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** -- I dispatch a fresh agent per task, review between tasks, fast iteration

2. **Inline Execution** -- I execute tasks in this session, batch execution with checkpoints

Which approach?