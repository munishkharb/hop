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

    // The private-window request must reach the browser even when it is already
    // running. `open --args` only feeds argv to main() when the app launches, so
    // openPrivate has to start a new process (`-n`) that carries the flag and the
    // URL in argv; Chromium and Firefox hand that request to the running instance.
    func testOpenPrivatePassesFlagAndURLToANewProcess() {
        let browser = Browser(
            id: "com.google.Chrome",
            name: "Chrome",
            path: URL(fileURLWithPath: "/Applications/Google Chrome.app"),
            privateFlag: "--incognito"
        )
        var captured: [String]?
        BrowserLauncher.openPrivate(
            url: URL(string: "https://example.com/?q=1")!,
            in: browser,
            runOpen: { captured = $0 }
        )
        XCTAssertEqual(captured, [
            "-n", "-a", "/Applications/Google Chrome.app",
            "--args", "--incognito", "https://example.com/?q=1",
        ])
    }
}
