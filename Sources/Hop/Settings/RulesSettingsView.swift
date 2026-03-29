import SwiftUI

struct RulesSettingsView: View {
    @ObservedObject var ruleStore: RuleStore
    let browsers: [Browser]
    @State private var showAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(ruleStore.rules) { rule in
                    RuleRowView(rule: rule, browsers: browsers) { updated in
                        ruleStore.update(updated)
                    }
                }
                .onMove { source, destination in
                    ruleStore.move(from: source, to: destination)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        ruleStore.delete(ruleStore.rules[index].id)
                    }
                }
            }

            Divider()

            HStack {
                Button(action: { showAddSheet = true }) {
                    Label("Add Rule", systemImage: "plus")
                }
                Spacer()
                Text("\(ruleStore.rules.count) rules")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(8)
        }
        .sheet(isPresented: $showAddSheet) {
            AddRuleSheet(browsers: browsers) { newRule in
                ruleStore.add(newRule)
            }
        }
    }
}

struct RuleRowView: View {
    let rule: Rule
    let browsers: [Browser]
    let onUpdate: (Rule) -> Void

    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { enabled in
                    var updated = rule
                    updated.isEnabled = enabled
                    onUpdate(updated)
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            VStack(alignment: .leading) {
                Text(rule.pattern)
                    .font(.system(size: 13, design: .monospaced))
                if let browser = browsers.first(where: { $0.id == rule.browserID }) {
                    Text(browser.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}

struct AddRuleSheet: View {
    let browsers: [Browser]
    let onAdd: (Rule) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var pattern = ""
    @State private var selectedBrowserID = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New Rule").font(.headline)

            TextField("Pattern (e.g. example.com)", text: $pattern)
                .textFieldStyle(.roundedBorder)

            Picker("Open in:", selection: $selectedBrowserID) {
                ForEach(browsers) { browser in
                    Text(browser.name).tag(browser.id)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") {
                    guard !pattern.isEmpty, !selectedBrowserID.isEmpty else { return }
                    onAdd(Rule(pattern: pattern, browserID: selectedBrowserID))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(pattern.isEmpty || selectedBrowserID.isEmpty)
            }
        }
        .padding()
        .frame(width: 350)
        .onAppear {
            selectedBrowserID = browsers.first?.id ?? ""
        }
    }
}
