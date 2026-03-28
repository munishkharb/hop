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
