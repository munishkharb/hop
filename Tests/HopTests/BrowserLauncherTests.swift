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
