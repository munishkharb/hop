import SwiftUI

struct HistorySettingsView: View {
    @ObservedObject var historyStore: HistoryStore
    let browsers: [Browser]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(historyStore.entries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.url)
                                .font(.system(size: 12, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            HStack(spacing: 4) {
                                if let browser = browsers.first(where: { $0.id == entry.browserID }) {
                                    Text(browser.name)
                                }
                                Text("·")
                                Text(entry.timestamp, style: .relative)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }

            Divider()

            HStack {
                Button(role: .destructive, action: { historyStore.clearAll() }) {
                    Label("Clear All", systemImage: "trash")
                }
                Spacer()
                Text("\(historyStore.entries.count) entries")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(8)
        }
    }
}
