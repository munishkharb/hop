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
        // A pattern made only of slashes (or empty) splits to nothing. Such a rule
        // names no domain, so it can never match; skip it instead of indexing into
        // an empty array.
        let parts = pattern.split(separator: "/", maxSplits: 1)
        guard let first = parts.first else { return false }
        let domainPattern = String(first)
        let pathPattern = parts.count > 1 ? "/" + String(parts[1]) : nil

        let domainMatches = host == domainPattern || host.hasSuffix("." + domainPattern)
        guard domainMatches else { return false }

        guard let pathPattern else { return true }

        return pathGlobMatch(path: path, pattern: pathPattern)
    }

    private func pathGlobMatch(path: String, pattern: String) -> Bool {
        let hasWildcard = pattern.hasSuffix("*")
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
            .replacingOccurrences(of: "\\*", with: ".*")
        // Only a pattern that explicitly ends in "*" gets open-ended matching;
        // otherwise require an exact match or a "/"-bounded continuation
        // (so "/admin" matches "/admin" and "/admin/settings" but not "/administration").
        let regexPattern = hasWildcard
            ? "^" + escaped + "$"
            : "^" + escaped + "(/.*)?$"
        guard let regex = try? NSRegularExpression(pattern: regexPattern) else { return false }
        let range = NSRange(path.startIndex..., in: path)
        return regex.firstMatch(in: path, range: range) != nil
    }
}
