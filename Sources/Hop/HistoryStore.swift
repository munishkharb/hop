import Foundation

final class HistoryStore: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    private let fileURL: URL
    private let maxEntries = 50

    init(directory: URL) {
        self.fileURL = directory.appendingPathComponent("history.json")
        self.entries = Self.load(from: fileURL)
    }

    func add(url: String, browserID: String) {
        let entry = HistoryEntry(url: url, browserID: browserID)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        save()
    }

    func recent(_ count: Int) -> [HistoryEntry] {
        Array(entries.prefix(count))
    }

    func clearAll() {
        entries.removeAll()
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func load(from url: URL) -> [HistoryEntry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([HistoryEntry].self, from: data)) ?? []
    }
}
