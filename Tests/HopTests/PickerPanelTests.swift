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

    private func drainMainQueue() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
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
        drainMainQueue()

        XCTAssertEqual(shownURL(panel), second)
        XCTAssertTrue(panel.isVisible)
        press("1", keyCode: 18, in: panel)
        drainMainQueue()

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
        drainMainQueue()

        XCTAssertEqual(dismissed, [first])
        XCTAssertEqual(shownURL(panel), second)
        press("1", keyCode: 18, in: panel)
        drainMainQueue()

        XCTAssertEqual(opened, [second])
        XCTAssertEqual(dismissed, [first])
    }
}
