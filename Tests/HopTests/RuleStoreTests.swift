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
