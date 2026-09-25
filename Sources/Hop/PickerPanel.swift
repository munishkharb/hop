import AppKit

final class PickerPanel: NSPanel {
    /// One link waiting for the user to pick a browser.
    private struct Request {
        let point: NSPoint
        let url: URL
        let browsers: [Browser]
        let onSelect: (Browser, Bool) -> Void
        let onDismiss: () -> Void
    }

    /// The request on screen, if any. Links that arrive while it is showing wait
    /// in `pending` and are shown in order, so none is replaced before the user
    /// has answered for it.
    private var current: Request?
    private var pending: [Request] = []

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
        let request = Request(
            point: point, url: url, browsers: browsers,
            onSelect: onSelect, onDismiss: onDismiss
        )
        if current != nil {
            pending.append(request)
            return
        }
        present(request)
    }

    /// Finish the request on screen exactly once, then show the next waiting link.
    /// Closing the panel triggers resignKey, which lands here again; `current`
    /// is cleared first so that second call does nothing.
    private func finishCurrent(_ action: (Request) -> Void) {
        guard let request = current else { return }
        current = nil
        close()
        action(request)
        if !pending.isEmpty {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.current == nil, !self.pending.isEmpty else { return }
                self.present(self.pending.removeFirst())
            }
        }
    }

    private func present(_ request: Request) {
        current = request
        let point = request.point
        let browsers = request.browsers

        let viewController = PickerViewController(
            url: request.url,
            browsers: browsers,
            onSelect: { [weak self] browser, isPrivate in
                self?.finishCurrent { $0.onSelect(browser, isPrivate) }
            },
            onCancel: { [weak self] in
                self?.finishCurrent { $0.onDismiss() }
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

    // Borderless panels refuse key status by default, which would leave the
    // number keys, Escape and resignKey dismissal dead.
    override var canBecomeKey: Bool { true }

    // Key presses go to the first responder, which is the SwiftUI hosting view,
    // and it swallows them before PickerViewController.keyDown runs. Handle the
    // picker's shortcuts here, before the view hierarchy sees the event.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown,
           let picker = contentViewController as? PickerViewController,
           picker.handleKey(event) {
            return
        }
        super.sendEvent(event)
    }

    override func resignKey() {
        super.resignKey()
        finishCurrent { $0.onDismiss() }
    }

    override func cancelOperation(_ sender: Any?) {
        finishCurrent { $0.onDismiss() }
    }
}
