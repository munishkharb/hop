import Foundation

final class RuleStore: ObservableObject {
    @Published private(set) var rules: [Rule] = []
    private let fileURL: URL

    init(directory: URL) {
        self.fileURL = directory.appendingPathComponent("rules.json")
        self.rules = Self.load(from: fileURL)
    }

    func add(_ rule: Rule) {
        rules.append(rule)
        save()
    }

    func delete(_ id: UUID) {
        rules.removeAll { $0.id == id }
        save()
    }

    func update(_ rule: Rule) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index] = rule
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        rules.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func replaceAll(_ newRules: [Rule]) {
        rules = newRules
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(rules) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func load(from url: URL) -> [Rule] {
        guard let data = try? Data(contentsOf: url),
              let rules = try? JSONDecoder().decode([Rule].self, from: data)
        else { return [] }
        return rules
    }
}
