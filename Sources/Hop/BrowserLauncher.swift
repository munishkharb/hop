import AppKit

final class BrowserLauncher {

    /// Open URL in the specified browser normally.
    static func open(url: URL, in browser: Browser) {
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: browser.path,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    /// Open URL in the specified browser in private/incognito mode.
    /// Falls back to normal open if browser has no private flag.
    static func openPrivate(url: URL, in browser: Browser) {
        guard let flag = browser.privateFlag else {
            open(url: url, in: browser)
            return
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", browser.path.path, url.absoluteString, "--args", flag]
        try? task.run()
    }

    /// Build the private-mode argument list (for testing).
    static func privateArgs(for url: URL, flag: String?) -> [String]? {
        guard let flag else { return nil }
        return [flag, url.absoluteString]
    }
}
