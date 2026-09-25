import XCTest
@testable import Hop

final class RuleEngineTests: XCTestCase {

    let chromeBeta = "com.google.Chrome.beta"

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

    func testPathWithoutWildcardDoesNotPrefixMatch() {
        let rules = [Rule(pattern: "example.com/admin", browserID: chromeBeta)]
        let engine = RuleEngine(rules: rules)
        XCTAssertEqual(engine.evaluate(url: URL(string: "https://example.com/admin")!), chromeBeta)
        XCTAssertEqual(engine.evaluate(url: URL(string: "https://example.com/admin/users")!), chromeBeta)
        XCTAssertNil(engine.evaluate(url: URL(string: "https://example.com/administration")!))
        XCTAssertNil(engine.evaluate(url: URL(string: "https://example.com/admin-panel-public")!))
    }

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

    func testPatternWithNoDomainNeverMatchesAndDoesNotCrash() {
        for pattern in ["", "/", "//", "/admin"] {
            let engine = RuleEngine(rules: [
                Rule(pattern: pattern, browserID: "com.apple.Safari"),
                Rule(pattern: "example.com", browserID: chromeBeta),
            ])
            let result = engine.evaluate(url: URL(string: "https://example.com/admin")!)
            XCTAssertEqual(result, chromeBeta, "pattern \(pattern.debugDescription) should be skipped")
        }
    }

    func testMiddleWildcardsWithFixedTail() {
        let rules = [Rule(pattern: "github.com/*/*/pull/*/files", browserID: chromeBeta)]
        let engine = RuleEngine(rules: rules)
        XCTAssertEqual(engine.evaluate(url: URL(string: "https://github.com/org/repo/pull/42/files")!), chromeBeta)
        XCTAssertEqual(engine.evaluate(url: URL(string: "https://github.com/org/repo/pull/42/files/abc")!), chromeBeta)
        XCTAssertNil(engine.evaluate(url: URL(string: "https://github.com/org/repo/pull/42")!))
        XCTAssertNil(engine.evaluate(url: URL(string: "https://github.com/org/repo/pull/42/filesx")!))
    }

    func testWildcardMatchesEmptySegmentAndSlashes() {
        let rules = [Rule(pattern: "example.com/a*b", browserID: chromeBeta)]
        let engine = RuleEngine(rules: rules)
        XCTAssertEqual(engine.evaluate(url: URL(string: "https://example.com/ab")!), chromeBeta)
        XCTAssertEqual(engine.evaluate(url: URL(string: "https://example.com/a/x/y/b")!), chromeBeta)
        XCTAssertNil(engine.evaluate(url: URL(string: "https://example.com/a/x/y/c")!))
    }

    func testLongLinkAgainstMultiWildcardRuleStaysFast() {
        // Several wildcards followed by a fixed tail used to backtrack
        // polynomially; the link author controls the path length.
        let rules = [Rule(pattern: "github.com/*/*/pull/*/files", browserID: chromeBeta)]
        let engine = RuleEngine(rules: rules)
        let url = URL(string: "https://github.com" + String(repeating: "/pull/", count: 1000))!
        let start = Date()
        XCTAssertNil(engine.evaluate(url: url))
        XCTAssertLessThan(Date().timeIntervalSince(start), 0.5)
    }

    func testPatternCharactersOtherThanStarAreLiteral() {
        let rules = [Rule(pattern: "example.com/a.c+(d)", browserID: chromeBeta)]
        let engine = RuleEngine(rules: rules)
        XCTAssertEqual(engine.evaluate(url: URL(string: "https://example.com/a.c+(d)")!), chromeBeta)
        XCTAssertNil(engine.evaluate(url: URL(string: "https://example.com/abcc(d)")!))
    }
}
