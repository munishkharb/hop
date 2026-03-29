import SwiftUI

struct SettingsView: View {
    @ObservedObject var ruleStore: RuleStore
    @ObservedObject var historyStore: HistoryStore
    @Binding var browsers: [Browser]
    let onRedetectBrowsers: () -> Void
    let onImportVelja: () -> Void

    var body: some View {
        TabView {
            RulesSettingsView(ruleStore: ruleStore, browsers: browsers)
                .tabItem { Label("Rules", systemImage: "list.bullet") }

            BrowsersSettingsView(browsers: $browsers, onRedetect: onRedetectBrowsers)
                .tabItem { Label("Browsers", systemImage: "globe") }

            HistorySettingsView(historyStore: historyStore, browsers: browsers)
                .tabItem { Label("History", systemImage: "clock") }

            GeneralSettingsView(onImportVelja: onImportVelja)
                .tabItem { Label("General", systemImage: "gear") }
        }
        .frame(width: 500, height: 400)
    }
}
