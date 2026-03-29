import Foundation

enum VeljaMigrator {

    /// Check if Velja rules exist using defaults CLI (cfprefsd blocks direct access)
    static func hasVeljaData(in defaults: UserDefaults? = nil) -> Bool {
        if let defaults {
            let rules = defaults.array(forKey: "rules") as? [String] ?? []
            return !rules.isEmpty
        }
        return !readVeljaRulesViaDefaults().isEmpty
    }

    /// Import rules from Velja
    static func importFromVelja(defaults: UserDefaults? = nil) -> [Rule] {
        if let defaults {
            let ruleStrings = defaults.array(forKey: "rules") as? [String] ?? []
            return parseVeljaRules(from: ruleStrings)
        }
        return parseVeljaRules(from: readVeljaRulesViaDefaults())
    }

    /// Read Velja rules via `defaults export` since cfprefsd blocks UserDefaults(suiteName:)
    private static func readVeljaRulesViaDefaults() -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["read", "com.sindresorhus.Velja", "rules"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8), !output.isEmpty else { return [] }

        // `defaults read` outputs an NSArray plist format: ( "json1", "json2" )
        // Parse it as a plist
        guard let plistData = output.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil),
              let array = plist as? [String]
        else {
            // Fallback: extract quoted strings manually
            return extractQuotedStrings(from: output)
        }

        return array
    }

    /// Fallback parser for defaults output format
    private static func extractQuotedStrings(from output: String) -> [String] {
        var results: [String] = []
        let scanner = Scanner(string: output)
        scanner.charactersToBeSkipped = nil

        while !scanner.isAtEnd {
            if scanner.scanString("\"") != nil {
                var jsonStr = ""
                var escaped = false
                while !scanner.isAtEnd {
                    guard let ch = scanner.scanCharacter() else { break }
                    if escaped {
                        jsonStr.append(ch)
                        escaped = false
                    } else if ch == "\\" {
                        // Check next char - defaults escapes quotes and backslashes
                        if let next = scanner.scanCharacter() {
                            if next == "\"" {
                                jsonStr.append("\"")
                            } else if next == "\\" {
                                jsonStr.append("\\")
                            } else {
                                jsonStr.append(ch)
                                jsonStr.append(next)
                            }
                        }
                    } else if ch == "\"" {
                        break
                    } else {
                        jsonStr.append(ch)
                    }
                }
                if !jsonStr.isEmpty {
                    results.append(jsonStr)
                }
            } else {
                _ = scanner.scanCharacter()
            }
        }

        return results
    }

    /// Parse Velja rule JSON strings into Hop Rule objects
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
