import AppKit

/// The menu bar version of the app icon's hop glyph (see icon/render_icon.swift):
/// one arc from a launch dot, landing arrow first on the chosen browser. The two
/// "not chosen" rings are left out because they vanish at menu bar size.
/// Drawn as a template image so macOS tints it for light and dark menu bars.
enum MenuBarIcon {
    static func make(pointSize: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize), flipped: false) { rect in
            let g = rect.width * 0.92
            func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
                NSPoint(x: rect.midX + x * g, y: rect.midY + y * g)
            }
            let baseline: CGFloat = -0.30
            let launch = p(-0.40, baseline)
            let control = p(-0.08, 0.92)
            let arcEnd = p(0.25, 0.04)
            let target = p(0.30, baseline)

            NSColor.black.setStroke()
            NSColor.black.setFill()

            let arc = NSBezierPath()
            arc.move(to: launch)
            arc.curve(to: arcEnd,
                      controlPoint1: NSPoint(x: launch.x + (control.x - launch.x) * 2 / 3,
                                             y: launch.y + (control.y - launch.y) * 2 / 3),
                      controlPoint2: NSPoint(x: arcEnd.x + (control.x - arcEnd.x) * 2 / 3,
                                             y: arcEnd.y + (control.y - arcEnd.y) * 2 / 3))
            arc.lineWidth = g * 0.12
            arc.lineCapStyle = .round
            arc.stroke()

            // Arrowhead along the arc's final tangent.
            let dx = arcEnd.x - control.x, dy = arcEnd.y - control.y
            let len = (dx * dx + dy * dy).squareRoot()
            let d = NSPoint(x: dx / len, y: dy / len)
            let n = NSPoint(x: -d.y, y: d.x)
            let size = g * 0.2
            let base = NSPoint(x: arcEnd.x - d.x * size * 0.3, y: arcEnd.y - d.y * size * 0.3)
            let head = NSBezierPath()
            head.move(to: NSPoint(x: arcEnd.x + d.x * size, y: arcEnd.y + d.y * size))
            head.line(to: NSPoint(x: base.x + n.x * size * 0.6, y: base.y + n.y * size * 0.6))
            head.line(to: NSPoint(x: base.x - n.x * size * 0.6, y: base.y - n.y * size * 0.6))
            head.close()
            head.fill()

            let r = g * 0.1
            for c in [launch, target] {
                NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)).fill()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Hop"
        return image
    }
}
