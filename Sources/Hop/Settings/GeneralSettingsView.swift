import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    let onImportVelja: () -> Void

    @State private var isDefaultBrowser = DefaultBrowser.isCurrent()

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

            Section("Migration") {
                Button("Import Rules from Velja") {
                    onImportVelja()
                }
                .disabled(!VeljaMigrator.hasVeljaData())
                Text("Reads existing Velja rules and adds them to Hop.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("About") {
                Text("Hop v1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("A lightweight browser picker for macOS.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { isDefaultBrowser = DefaultBrowser.isCurrent() }
    }
}
