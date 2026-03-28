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
