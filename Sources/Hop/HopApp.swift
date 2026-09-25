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
                } else {
                    BrowserLauncher.open(url: url, in: browser)
                    self?.historyStore.add(url: url.absoluteString, browserID: browser.id)
                }
            },
            onDismiss: { }
        )
    }

    // MARK: - Menu Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = MenuBarIcon.make()
        }
        updateMenu()
    }

    func updateMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: isEnabled ? "Enabled" : "Disabled",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = isEnabled ? .on : .off
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

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
                let attrTitle = NSAttributedString(
                    string: "\(displayURL) → \(browserName)",
                    attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)]
                )
                item.attributedTitle = attrTitle
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
