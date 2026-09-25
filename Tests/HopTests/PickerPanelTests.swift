import XCTest
import AppKit
@testable import Hop

final class PickerPanelTests: XCTestCase {

    private let browser = Browser(
        id: "test.browser",
        name: "Test",
        path: URL(fileURLWithPath: "/nonexistent/Test.app"),
        privateFlag: nil
    )
    private let first = URL(string: "https://first.invalid/")!
    private let second = URL(string: "https://second.invalid/")!

    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    private func shownURL(_ panel: PickerPanel) -> URL? {
        (panel.contentViewController as? PickerViewController)?.rootView.url
    }

    private func press(_ key: String, keyCode: UInt16, in panel: PickerPanel) {
        let event = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: 0, context: nil, characters: key,
            charactersIgnoringModifiers: key, isARepeat: false, keyCode: keyCode
        )!
        (panel.contentViewController as? PickerViewController)?.keyDown(with: event)
    }

    // The next queued link is shown from an async main-queue block. Run the main
    // run loop until the expected state appears rather than for a fixed time,
    // which was too short on a busy CI runner.
    private func runMainLoop(until condition: () -> Bool, timeout: TimeInterval = 2) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
    }

    func testSecondUnmatchedLinkWaitsForTheFirstChoice() {
        let panel = PickerPanel()
        defer { panel.close() }
        var opened: [URL] = []

        panel.showPicker(at: .zero, url: first, browsers: [browser],
                         onSelect: { _, _ in opened.append(self.first) }, onDismiss: {})
        panel.showPicker(at: .zero, url: second, browsers: [browser],
                         onSelect: { _, _ in opened.append(self.second) }, onDismiss: {})

        XCTAssertEqual(shownURL(panel), first)
        press("1", keyCode: 18, in: panel)
        runMainLoop(until: { shownURL(panel) == second })

        XCTAssertEqual(shownURL(panel), second)
        XCTAssertTrue(panel.isVisible)
        press("1", keyCode: 18, in: panel)
        runMainLoop(until: { opened.count == 2 })

        XCTAssertEqual(opened, [first, second])
    }

    func testDismissingFirstLinkShowsTheNext() {
        let panel = PickerPanel()
        defer { panel.close() }
        var dismissed: [URL] = []
        var opened: [URL] = []

        panel.showPicker(at: .zero, url: first, browsers: [browser],
                         onSelect: { _, _ in opened.append(self.first) },
                         onDismiss: { dismissed.append(self.first) })
        panel.showPicker(at: .zero, url: second, browsers: [browser],
                         onSelect: { _, _ in opened.append(self.second) },
                         onDismiss: { dismissed.append(self.second) })

        press("\u{1b}", keyCode: 53, in: panel)
        runMainLoop(until: { shownURL(panel) == second })

        XCTAssertEqual(dismissed, [first])
        XCTAssertEqual(shownURL(panel), second)
        press("1", keyCode: 18, in: panel)
        runMainLoop(until: { !opened.isEmpty })

        XCTAssertEqual(opened, [second])
        XCTAssertEqual(dismissed, [first])
    }
}

final class PickerKeyboardTests: XCTestCase {

    private let browser = Browser(
        id: "com.google.Chrome",
        name: "Chrome",
        path: URL(fileURLWithPath: "/nonexistent/Chrome.app"),
        privateFlag: "--incognito"
    )

    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    // Option changes the typed character (Option-1 is "¡" on a US layout), so the
    // digit has to come from charactersIgnoringModifiers or Option+number does nothing.
    func testOptionNumberOpensThatBrowserPrivately() {
        var picked: (Browser, Bool)?
        let controller = PickerViewController(
            url: URL(string: "https://example.com/")!,
            browsers: [browser],
            onSelect: { picked = ($0, $1) },
            onCancel: {}
        )
        let event = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [.option], timestamp: 0,
            windowNumber: 0, context: nil, characters: "¡",
            charactersIgnoringModifiers: "1", isARepeat: false, keyCode: 18
        )!
        controller.keyDown(with: event)

        XCTAssertEqual(picked?.0, browser)
        XCTAssertEqual(picked?.1, true)
    }
}

final class PickerPanelKeyWindowTests: XCTestCase {
    // A borderless panel cannot become key by default, and then number keys,
    // Escape and dismiss-on-focus-loss never reach the picker in the real app.
    func testPickerPanelCanBecomeKey() {
        _ = NSApplication.shared
        XCTAssertTrue(PickerPanel().canBecomeKey)
    }
}

final class PickerPanelKeyRoutingTests: XCTestCase {
    // Real key presses reach the panel through NSWindow.sendEvent and the
    // responder chain, not by calling the view controller's keyDown directly.
    func testOptionNumberSentThroughTheWindowOpensPrivately() {
        _ = NSApplication.shared
        let browser = Browser(id: "com.google.Chrome", name: "Chrome",
                              path: URL(fileURLWithPath: "/nonexistent/Chrome.app"),
                              privateFlag: "--incognito")
        let panel = PickerPanel()
        defer { panel.close() }
        var picked: (Browser, Bool)?
        panel.showPicker(at: .zero, url: URL(string: "https://example.com/")!, browsers: [browser],
                         onSelect: { picked = ($0, $1) }, onDismiss: {})
        let event = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [.option], timestamp: 0,
            windowNumber: panel.windowNumber, context: nil, characters: "¡",
            charactersIgnoringModifiers: "1", isARepeat: false, keyCode: 18
        )!
        panel.sendEvent(event)

        XCTAssertEqual(picked?.0, browser)
        XCTAssertEqual(picked?.1, true)
    }
}

final class PickerOptionStateTests: XCTestCase {
    // Holding Option switches the rows to show which browsers open privately.
    func testHoldingOptionIsTrackedFromFlagsChanged() {
        _ = NSApplication.shared
        let browser = Browser(id: "test.browser", name: "Test",
                              path: URL(fileURLWithPath: "/nonexistent/Test.app"), privateFlag: nil)
        let panel = PickerPanel()
        defer { panel.close() }
        panel.showPicker(at: .zero, url: URL(string: "https://example.com/")!, browsers: [browser],
                         onSelect: { _, _ in }, onDismiss: {})
        let picker = panel.contentViewController as? PickerViewController

        func flags(_ f: NSEvent.ModifierFlags) -> NSEvent {
            NSEvent.keyEvent(with: .flagsChanged, location: .zero, modifierFlags: f, timestamp: 0,
                             windowNumber: panel.windowNumber, context: nil, characters: "",
                             charactersIgnoringModifiers: "", isARepeat: false, keyCode: 58)!
        }
        panel.sendEvent(flags([.option]))
        XCTAssertEqual(picker?.modifiers.optionHeld, true)
        panel.sendEvent(flags([]))
        XCTAssertEqual(picker?.modifiers.optionHeld, false)
    }
}
