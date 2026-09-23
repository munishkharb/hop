import AppKit

/// Reads and sets whether Hop is the system default handler for web links.
/// macOS never prompts an app to become the default browser on its own, so the
/// General settings tab exposes this explicitly.
enum DefaultBrowser {
    private static let probeURL = URL(string: "https://example.com")!

    /// True when Hop is the current handler for https links.
    static func isCurrent() -> Bool {
        guard let handler = NSWorkspace.shared.urlForApplication(toOpen: probeURL) else {
            return false
        }
        return handler.standardizedFileURL == Bundle.main.bundleURL.standardizedFileURL
    }

    /// Requests Hop as the handler for http and https. macOS shows its own
    /// confirmation alert; the completion reports the resulting state on the main queue.
    static func setAsDefault(completion: @escaping (Bool) -> Void) {
        let appURL = Bundle.main.bundleURL
        let group = DispatchGroup()
        for scheme in ["http", "https"] {
            group.enter()
            NSWorkspace.shared.setDefaultApplication(at: appURL, toOpenURLsWithScheme: scheme) { _ in
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(isCurrent())
        }
    }
}
