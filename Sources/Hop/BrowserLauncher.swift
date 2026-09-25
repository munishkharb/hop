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
    static func openPrivate(
        url: URL,
        in browser: Browser,
        runOpen: ([String]) -> Void = runOpenCommand
    ) {
        guard let browserArgs = privateArgs(for: url, flag: browser.privateFlag) else {
            open(url: url, in: browser)
            return
        }
        // `open --args` only reaches the browser's main() when a process starts, so
        // a plain `open -a` to a browser that is already running delivers the URL
        // and drops the flag. `-n` starts a fresh process that receives the flag
        // and the URL in argv; Chromium- and Firefox-based browsers pass that
        // request on to the running instance, which opens a private window.
        runOpen(["-n", "-a", browser.path.path, "--args"] + browserArgs)
        // `open -n` activates the short-lived process it started, not the running
        // browser, so the private window opened behind the current app. A plain
        // `open -a` brings the browser forward; with windows open it adds none.
        runOpen(["-a", browser.path.path])
    }

    /// Run /usr/bin/open with the given arguments.
    static func runOpenCommand(_ arguments: [String]) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = arguments
        try? task.run()
    }

    /// The arguments the browser itself receives for a private-window request.
    static func privateArgs(for url: URL, flag: String?) -> [String]? {
        guard let flag else { return nil }
        return [flag, url.absoluteString]
    }
}
