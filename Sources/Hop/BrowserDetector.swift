import AppKit

final class BrowserDetector {

    private static let privateFlagMap: [String: String] = [
        "com.google.Chrome": "--incognito",
        "com.google.Chrome.beta": "--incognito",
        "com.google.Chrome.canary": "--incognito",
        "com.brave.Browser": "--incognito",
        "com.brave.Browser.beta": "--incognito",
        "com.brave.Browser.nightly": "--incognito",
        "com.microsoft.edgemac": "--inprivate",
        "com.microsoft.edgemac.Beta": "--inprivate",
        "company.thebrowser.Browser": "--incognito",
        "org.chromium.Chromium": "--incognito",
        "org.mozilla.firefox": "-private-window",
        "org.mozilla.firefoxdeveloperedition": "-private-window",
    ]

    func detectBrowsers() -> [Browser] {
        guard let url = URL(string: "https://example.com") else { return [] }
        guard let appURLs = LSCopyApplicationURLsForURL(url as CFURL, .viewer)?.takeRetainedValue() as? [URL] else {
            return []
        }

        var seen = Set<String>()
        var browsers: [Browser] = []

        for appURL in appURLs {
            guard let bundle = Bundle(url: appURL),
                  let bundleID = bundle.bundleIdentifier,
                  !seen.contains(bundleID),
                  bundleID != "com.hop.browserPicker"
            else { continue }

            seen.insert(bundleID)

            let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? appURL.deletingPathExtension().lastPathComponent

            let privateFlag = Self.privateFlagMap[bundleID]

            browsers.append(Browser(
                id: bundleID,
                name: name,
                path: appURL,
                privateFlag: privateFlag
            ))
        }

        return browsers
    }
}
