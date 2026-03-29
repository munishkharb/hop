import AppKit

final class PickerPanel: NSPanel {
    private var onDismiss: (() -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .popUpMenu
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
    }

    func showPicker(
        at point: NSPoint,
        url: URL,
        browsers: [Browser],
        onSelect: @escaping (Browser, Bool) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onDismiss = onDismiss

        let viewController = PickerViewController(
            url: url,
            browsers: browsers,
            onSelect: { [weak self] browser, isPrivate in
                self?.close()
                onSelect(browser, isPrivate)
            },
            onCancel: { [weak self] in
                self?.close()
                onDismiss()
            }
        )

        contentViewController = viewController

        let browserCount = browsers.count
        let width: CGFloat = 320
        let height: CGFloat = CGFloat(70 + browserCount * 52)
        let frame = NSRect(
            x: point.x,
            y: point.y - height,
            width: width,
            height: height
        )
        setFrame(frame, display: true)

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            var adjustedFrame = frame
            if adjustedFrame.maxX > screenFrame.maxX {
                adjustedFrame.origin.x = screenFrame.maxX - width
            }
            if adjustedFrame.minY < screenFrame.minY {
                adjustedFrame.origin.y = screenFrame.minY
            }
            if adjustedFrame.minX < screenFrame.minX {
                adjustedFrame.origin.x = screenFrame.minX
            }
            setFrame(adjustedFrame, display: true)
        }

        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    override func resignKey() {
        super.resignKey()
        close()
        onDismiss?()
    }

    override func cancelOperation(_ sender: Any?) {
        close()
        onDismiss?()
    }
}
