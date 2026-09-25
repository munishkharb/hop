import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    let onImportVelja: () -> Void

    @State private var isDefaultBrowser = DefaultBrowser.isCurrent()
    // Velja users get an import button; everyone else never sees the section.
    @State private var hasVeljaRules = false

    static var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version.map { "Hop v\($0)" } ?? "Hop (development build)"
    }

    var body: some View {
        Form {
            Section("Default Browser") {
                if isDefaultBrowser {
                    Label("Hop is your default browser", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.secondary)
                } else {
                    Button("Set Hop as Default Browser") {
                        DefaultBrowser.setAsDefault { isDefault in
                            isDefaultBrowser = isDefault
                        }
                    }
                    Text("Routes every link you click through Hop's rules and picker.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        if newValue {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }
            }

            if hasVeljaRules {
                Section("Migration") {
                    Button("Import Rules from Velja") {
                        onImportVelja()
                    }
                    Text("Reads existing Velja rules and adds them to Hop.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("About") {
                Text(Self.versionText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("A lightweight browser picker for macOS.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            isDefaultBrowser = DefaultBrowser.isCurrent()
            hasVeljaRules = VeljaMigrator.hasVeljaData()
        }
    }
}
