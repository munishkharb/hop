import Foundation
import AppKit

struct Browser: Identifiable, Codable, Equatable {
    let id: String          // bundle identifier, e.g. "com.google.Chrome.beta"
    let name: String        // display name, e.g. "Chrome Beta"
    let path: URL           // path to .app bundle
    let privateFlag: String? // CLI flag for private mode, e.g. "--incognito"

    var icon: NSImage? {
        NSWorkspace.shared.icon(forFile: path.path)
    }
}

struct Rule: Identifiable, Codable {
    let id: UUID
    var pattern: String         // e.g. "example.com" or "github.com/my-org/*"
    var browserID: String       // bundle identifier of target browser
    var isEnabled: Bool

    init(pattern: String, browserID: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.pattern = pattern
        self.browserID = browserID
        self.isEnabled = isEnabled
    }
}

struct HistoryEntry: Identifiable, Codable {
    let id: UUID
    let url: String
    let browserID: String
    let timestamp: Date

    init(url: String, browserID: String) {
        self.id = UUID()
        self.url = url
        self.browserID = browserID
        self.timestamp = Date()
    }
}
