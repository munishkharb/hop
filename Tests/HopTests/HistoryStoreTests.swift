import XCTest
@testable import Hop

final class HistoryStoreTests: XCTestCase {
    var tempDir: URL!
    var store: HistoryStore!

    override func setUp() {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = HistoryStore(directory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testEmptyByDefault() {
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testAddEntry() {
        store.add(url: "https://example.com", browserID: "com.google.Chrome")
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries[0].url, "https://example.com")
    }

    func testLimitedTo50Entries() {
        for i in 0..<60 {
            store.add(url: "https://example.com/\(i)", browserID: "com.google.Chrome")
        }
        XCTAssertEqual(store.entries.count, 50)
        XCTAssertEqual(store.entries[0].url, "https://example.com/59")
    }

    func testPersistsToDisk() {
        store.add(url: "https://example.com", browserID: "com.google.Chrome")
        let store2 = HistoryStore(directory: tempDir)
        XCTAssertEqual(store2.entries.count, 1)
    }

    func testClearAll() {
        store.add(url: "https://example.com", browserID: "com.google.Chrome")
        store.clearAll()
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testRecentReturnsLastN() {
        for i in 0..<20 {
            store.add(url: "https://example.com/\(i)", browserID: "com.google.Chrome")
        }
        let recent = store.recent(10)
        XCTAssertEqual(recent.count, 10)
        XCTAssertEqual(recent[0].url, "https://example.com/19")
    }
}
