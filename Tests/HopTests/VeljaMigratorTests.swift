import XCTest
@testable import Hop

final class VeljaMigratorTests: XCTestCase {

    func testParseVeljaRuleJSON() {
        let veljaJSON = """
        {"browser":"com.google.Chrome.beta","forceNewWindow":false,"id":"6E05E113-F2A4-4E98-A8B5-D47FB67DED06","isEnabled":true,"isTransformScriptEnabled":false,"matchers":[{"fixture":"https://ci.example.com","id":"16CD4262-6242-4FC4-A998-2D081B50E7E9","kind":"hostSuffix","pattern":"example.com"}],"onlyFromAirdrop":false,"openInBackground":false,"runAfterBuiltinRules":false,"sourceApps":[],"title":"example.com → Chrome Beta","transformScript":"","transformTestURL":""}
        """
        let rules = VeljaMigrator.parseVeljaRules(from: [veljaJSON])
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules[0].pattern, "example.com")
        XCTAssertEqual(rules[0].browserID, "com.google.Chrome.beta")
        XCTAssertTrue(rules[0].isEnabled)
    }

    func testParseMultipleVeljaRules() {
        let rulesJSON = [
            """
            {"browser":"com.google.Chrome.beta","isEnabled":true,"matchers":[{"kind":"hostSuffix","pattern":"example.com"}],"title":"test1"}
            """,
            """
            {"browser":"com.google.Chrome.beta","isEnabled":true,"matchers":[{"kind":"hostSuffix","pattern":"slack.com"}],"title":"test2"}
            """,
        ]
        let rules = VeljaMigrator.parseVeljaRules(from: rulesJSON)
        XCTAssertEqual(rules.count, 2)
        XCTAssertEqual(rules[0].pattern, "example.com")
        XCTAssertEqual(rules[1].pattern, "slack.com")
    }

    func testDisabledVeljaRuleStaysDisabled() {
        let json = """
        {"browser":"com.google.Chrome.beta","isEnabled":false,"matchers":[{"kind":"hostSuffix","pattern":"example.com"}],"title":"test"}
        """
        let rules = VeljaMigrator.parseVeljaRules(from: [json])
        XCTAssertEqual(rules.count, 1)
        XCTAssertFalse(rules[0].isEnabled)
    }

    func testHasVeljaDataReturnsFalseWhenNoData() {
        XCTAssertFalse(VeljaMigrator.hasVeljaData(in: UserDefaults(suiteName: UUID().uuidString)!))
    }
}
