import Foundation

final class RuleEngine {
    private let rules: [Rule]

    init(rules: [Rule]) {
        self.rules = rules
    }

    func evaluate(url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        let path = url.path.lowercased()

        for rule in rules where rule.isEnabled {
            if matches(host: host, path: path, pattern: rule.pattern.lowercased()) {
                return rule.browserID
            }
        }
        return nil
    }

    private func matches(host: String, path: String, pattern: String) -> Bool {
        let parts = pattern.split(separator: "/", maxSplits: 1)
        let domainPattern = String(parts[0])
        let pathPattern = parts.count > 1 ? "/" + String(parts[1]) : nil

        let domainMatches = host == domainPattern || host.hasSuffix("." + domainPattern)
        guard domainMatches else { return false }

        guard let pathPattern else { return true }

        return pathGlobMatch(path: path, pattern: pathPattern)
    }

    private func pathGlobMatch(path: String, pattern: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
        let regexPattern = "^" + escaped.replacingOccurrences(of: "\\*", with: ".*") + ".*$"
        guard let regex = try? NSRegularExpression(pattern: regexPattern) else { return false }
        let range = NSRange(path.startIndex..., in: path)
        return regex.firstMatch(in: path, range: range) != nil
    }
}
