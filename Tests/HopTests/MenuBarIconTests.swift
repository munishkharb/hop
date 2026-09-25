import XCTest
import AppKit
@testable import Hop

final class MenuBarIconTests: XCTestCase {
    // A template image is what lets macOS tint the icon for light and dark menu bars.
    func testMenuBarIconIsATemplateAtMenuBarSize() {
        let image = MenuBarIcon.make()
        XCTAssertTrue(image.isTemplate)
        XCTAssertEqual(image.size, NSSize(width: 18, height: 18))
    }
}
