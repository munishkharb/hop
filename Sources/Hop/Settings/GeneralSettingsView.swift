import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    let onImportVelja: () -> Void

    var body: some View {
        Form {
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
    }
}
