import AppKit
import SwiftUI

final class PickerViewController: NSHostingController<PickerContentView> {
    private let onSelectHandler: (Browser, Bool) -> Void
    private let onCancelHandler: () -> Void
    private let browserList: [Browser]

    init(
        url: URL,
        browsers: [Browser],
        onSelect: @escaping (Browser, Bool) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onSelectHandler = onSelect
        self.onCancelHandler = onCancel
        self.browserList = browsers
        let view = PickerContentView(
            url: url,
            browsers: browsers,
            onSelect: onSelect,
            onCancel: onCancel
        )
        super.init(rootView: view)
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func keyDown(with event: NSEvent) {
        if !handleKey(event) {
            super.keyDown(with: event)
        }
    }

    /// Handle the picker's shortcuts: Escape cancels, 1-9 pick a browser, and
    /// Option with a number opens it privately. Returns false for any other key.
    /// PickerPanel calls this from sendEvent, because the SwiftUI hosting view
    /// consumes key presses before they reach this controller's keyDown.
    func handleKey(_ event: NSEvent) -> Bool {
        if event.keyCode == 53 {
            onCancelHandler()
            return true
        }

        // Option changes the typed character (Option-1 is "¡"), so read the key
        // without modifiers.
        if let chars = event.charactersIgnoringModifiers, let digit = Int(chars), digit >= 1, digit <= browserList.count {
            let isPrivate = event.modifierFlags.contains(.option)
            onSelectHandler(browserList[digit - 1], isPrivate)
            return true
        }

        return false
    }
}

struct PickerContentView: View {
    let url: URL
    let browsers: [Browser]
    let onSelect: (Browser, Bool) -> Void
    let onCancel: () -> Void

    @State private var hoveredIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(url.absoluteString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider().padding(.horizontal, 8)

            ForEach(Array(browsers.enumerated()), id: \.element.id) { index, browser in
                BrowserRowView(
                    browser: browser,
                    index: index + 1,
                    isHovered: hoveredIndex == index,
                    onSelect: onSelect
                )
                .onHover { isHovered in
                    hoveredIndex = isHovered ? index : nil
                }
            }

            Divider().padding(.horizontal, 8)

            Text("⌥ Option + click for private window  ·  Esc to cancel")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .frame(width: 320)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct BrowserRowView: View {
    let browser: Browser
    let index: Int
    let isHovered: Bool
    let onSelect: (Browser, Bool) -> Void

    var body: some View {
        Button {
            let isPrivate = NSEvent.modifierFlags.contains(.option)
            onSelect(browser, isPrivate)
        } label: {
            HStack(spacing: 10) {
                Text("\(index)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(width: 18)

                if let icon = browser.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "globe")
                        .frame(width: 28, height: 28)
                }

                Text(browser.name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)

                Spacer()

                if browser.privateFlag != nil {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}
