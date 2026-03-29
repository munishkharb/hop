import SwiftUI

struct BrowsersSettingsView: View {
    @Binding var browsers: [Browser]
    let onRedetect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(Array(browsers.enumerated()), id: \.element.id) { index, browser in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(width: 20)

                        if let icon = browser.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }

                        VStack(alignment: .leading) {
                            Text(browser.name)
                                .font(.system(size: 13))
                            Text(browser.id)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if browser.privateFlag != nil {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .help("Private mode supported")
                        }
                    }
                }
                .onMove { source, destination in
                    browsers.move(fromOffsets: source, toOffset: destination)
                }
            }

            Divider()

            HStack {
                Button(action: onRedetect) {
                    Label("Re-detect Browsers", systemImage: "arrow.clockwise")
                }
                Spacer()
                Text("Drag to reorder. Order sets keyboard shortcuts in picker.")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(8)
        }
    }
}
