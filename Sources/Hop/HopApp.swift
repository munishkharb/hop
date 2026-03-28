import SwiftUI

@main
struct HopApp: App {
    var body: some Scene {
        MenuBarExtra("Hop", systemImage: "arrow.trianglehead.branch") {
            Text("Hop is running")
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
}
