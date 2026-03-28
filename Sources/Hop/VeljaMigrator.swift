import Foundation

enum VeljaMigrator {

    static func hasVeljaData(in defaults: UserDefaults = UserDefaults(suiteName: "com.sindresorhus.Velja") ?? .standard) -> Bool {
        let rules = defaults.array(forKey: "rules") as? [String] ?? []
        return !rules.isEmpty
    }

    static func importFromVelja(defaults: UserDefaults = UserDefaults(suiteName: "com.sindresorhus.Velja") ?? .standard) -> [Rule] {
        let ruleStrings = defaults.array(forKey: "rules") as? [String] ?? []
        return parseVeljaRules(from: ruleStrings)
    }

    static func parseVeljaRules(from jsonStrings: [String]) -> [Rule] {
        var rules: [Rule] = []

        for jsonString in jsonStrings {
            guard let data = jsonString.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let browserID = dict["browser"] as? String,
                  let matchers = dict["matchers"] as? [[String: Any]],
                  let firstMatcher = matchers.first,
                  let pattern = firstMatcher["pattern"] as? String
            else { continue }

            let isEnabled = dict["isEnabled"] as? Bool ?? true

            rules.append(Rule(
                pattern: pattern,
                browserID: browserID,
                isEnabled: isEnabled
            ))
        }

        return rules
    }
}
