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

    /// Match a path against a rule's path pattern, where "*" matches any run of
    /// characters (including "/" and the empty string) and everything else is literal.
    ///
    /// Only a pattern that explicitly ends in "*" gets open-ended matching;
    /// otherwise require an exact match or a "/"-bounded continuation
    /// (so "/admin" matches "/admin" and "/admin/settings" but not "/administration").
    private func pathGlobMatch(path: String, pattern: String) -> Bool {
        let pathBytes = Array(path.utf8)
        let patternBytes = Array(pattern.utf8)
        if pattern.hasSuffix("*") {
            return Self.globMatch(pathBytes, patternBytes)
        }
        return Self.globMatch(pathBytes, patternBytes)
            || Self.globMatch(pathBytes, patternBytes + Array("/*".utf8))
    }

    /// Iterative wildcard matcher. When a literal mismatches, it retries from the
    /// most recent "*" only, so the work is bounded by path length times pattern
    /// length no matter how many wildcards the pattern holds. A backtracking regex
    /// built from the same pattern grows polynomially in the path length with each
    /// extra wildcard, and the path comes from whoever wrote the link.
    static func globMatch(_ text: [UInt8], _ pattern: [UInt8]) -> Bool {
        let star = UInt8(ascii: "*")
        var t = 0
        var p = 0
        var lastStar: Int?
        var resumeAt = 0

        while t < text.count {
            if p < pattern.count, pattern[p] == star {
                lastStar = p
                p += 1
                resumeAt = t
            } else if p < pattern.count, pattern[p] == text[t] {
                p += 1
                t += 1
            } else if let starIndex = lastStar {
                p = starIndex + 1
                resumeAt += 1
                t = resumeAt
            } else {
                return false
            }
        }
        while p < pattern.count, pattern[p] == star {
            p += 1
        }
        return p == pattern.count
    }
}
