import Foundation

enum RouteResult {
    case autoOpen(browserID: String)
    case showPicker
}

final class URLRouter {
    private let ruleEngine: RuleEngine

    init(rules: [Rule]) {
        self.ruleEngine = RuleEngine(rules: rules)
    }

    func route(url: URL) -> RouteResult {
        if let browserID = ruleEngine.evaluate(url: url) {
            return .autoOpen(browserID: browserID)
        }
        return .showPicker
    }
}
