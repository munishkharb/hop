// render_icon.swift
//
// Renders the hop app icon at 1024x1024 in two color variants (blue, teal).
// Pure CoreGraphics + ImageIO, no AppKit, so it runs headless via:
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift render_icon.swift
//
// Run from inside the icon/ directory; it writes the two PNGs next to itself.
//
// The icon tile is a superellipse ("squircle") filled with a vertical linear
// gradient. Centered on the tile is a custom hop glyph: one bold arc that
// takes off from a launch dot and lands, arrow first, on the chosen browser
// (a solid dot between two rings). Every path below is drawn by hand with CGMutablePath;
// no system symbol font or SF Symbol is used anywhere in this file.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Canvas

let canvasSize = 1024
let canvasSizeF = CGFloat(canvasSize)

// MARK: - Color model

struct RGB {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
}

struct Palette {
    let name: String
    let top: RGB    // brighter stop, top of the tile
    let bottom: RGB // deeper stop, bottom of the tile
}

let palettes: [Palette] = [
    Palette(
        name: "blue",
        top: RGB(r: 0.36, g: 0.64, b: 0.98),
        bottom: RGB(r: 0.05, g: 0.16, b: 0.47)
    ),
    Palette(
        name: "teal",
        top: RGB(r: 0.27, g: 0.88, b: 0.80),
        bottom: RGB(r: 0.03, g: 0.31, b: 0.33)
    ),
]

// MARK: - Vector helpers

func signedPow(_ value: CGFloat, _ exponent: CGFloat) -> CGFloat {
    if value == 0 { return 0 }
    let sign: CGFloat = value < 0 ? -1 : 1
    return sign * CGFloat(pow(Double(abs(value)), Double(exponent)))
}

struct Vec {
    var x: CGFloat
    var y: CGFloat

    static func - (a: Vec, b: Vec) -> Vec { Vec(x: a.x - b.x, y: a.y - b.y) }
    static func + (a: Vec, b: Vec) -> Vec { Vec(x: a.x + b.x, y: a.y + b.y) }
    static func * (a: Vec, s: CGFloat) -> Vec { Vec(x: a.x * s, y: a.y * s) }

    var length: CGFloat { (x * x + y * y).squareRoot() }
    var normalized: Vec { let l = length; return l == 0 ? self : Vec(x: x / l, y: y / l) }
    var perpendicular: Vec { Vec(x: -y, y: x) }
    var point: CGPoint { CGPoint(x: x, y: y) }
}

// MARK: - Squircle (superellipse) tile shape

// Standard Lame-curve parametrization, traced with straight segments dense
// enough to read as a smooth continuous curve at 1024px. This is the
// "modern rounded-square app tile" silhouette, not a plain rounded rect.
func squirclePath(center: CGPoint, halfWidth: CGFloat, halfHeight: CGFloat, exponent: CGFloat, steps: Int = 720) -> CGPath {
    let path = CGMutablePath()
    for i in 0...steps {
        let t = (CGFloat(i) / CGFloat(steps)) * 2 * CGFloat.pi
        let ct = cos(t)
        let st = sin(t)
        let x = halfWidth * signedPow(ct, 2 / exponent)
        let y = halfHeight * signedPow(st, 2 / exponent)
        let p = CGPoint(x: center.x + x, y: center.y + y)
        if i == 0 {
            path.move(to: p)
        } else {
            path.addLine(to: p)
        }
    }
    path.closeSubpath()
    return path
}

// MARK: - Hop glyph (original artwork, not a system symbol)

// A link taking off from a launch point and hopping, along one bold arc, onto
// the browser it was sent to: a solid dot between two rings (the browsers it
// did not go to). The arc ends in a filled arrowhead just above its target.
// Coordinates are defined in a local -0.5...0.5 unit box (y up), then
// scaled/translated onto the tile. The menu bar icon in
// Sources/Hop/MenuBarIcon.swift draws the same geometry; keep them in step.
struct GlyphPaths {
    let arcPath: CGPath
    let arcWidth: CGFloat
    let fillPath: CGPath   // arrowhead, launch dot, chosen-browser dot
    let ringPath: CGPath   // the two browsers not chosen
    let ringWidth: CGFloat
}

func buildGlyph(center: CGPoint, glyphSize: CGFloat) -> GlyphPaths {
    let baseline: CGFloat = -0.20
    let launch = Vec(x: -0.44, y: baseline)
    let control = Vec(x: -0.08, y: 0.82)
    let arcEnd = Vec(x: 0.21, y: 0.01)
    let target = Vec(x: 0.24, y: baseline)
    let rings = [Vec(x: 0.04, y: baseline), Vec(x: 0.44, y: baseline)]

    func toCanvas(_ v: Vec) -> CGPoint {
        CGPoint(x: center.x + v.x * glyphSize, y: center.y + v.y * glyphSize)
    }
    func circle(_ c: Vec, _ r: CGFloat) -> CGRect {
        let p = toCanvas(c)
        let rr = r * glyphSize
        return CGRect(x: p.x - rr, y: p.y - rr, width: rr * 2, height: rr * 2)
    }

    let arc = CGMutablePath()
    arc.move(to: toCanvas(launch))
    arc.addQuadCurve(to: toCanvas(arcEnd), control: toCanvas(control))

    // Arrowhead continues the arc's final tangent (control -> end), with its
    // base flared wider than the stroke so it reads as a triangle.
    let dir = (arcEnd - control).normalized
    let perp = dir.perpendicular
    let size: CGFloat = 0.15
    let base = arcEnd - dir * (size * 0.3)
    let fill = CGMutablePath()
    fill.move(to: toCanvas(arcEnd + dir * size))
    fill.addLine(to: toCanvas(base + perp * (size * 0.62)))
    fill.addLine(to: toCanvas(base - perp * (size * 0.62)))
    fill.closeSubpath()
    fill.addEllipse(in: circle(launch, 0.075))
    fill.addEllipse(in: circle(target, 0.075))

    let ringPath = CGMutablePath()
    for r in rings { ringPath.addEllipse(in: circle(r, 0.055)) }

    return GlyphPaths(
        arcPath: arc, arcWidth: glyphSize * 0.095,
        fillPath: fill,
        ringPath: ringPath, ringWidth: glyphSize * 0.03
    )
}

// MARK: - Rendering

func renderIcon(palette: Palette) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: canvasSize,
        height: canvasSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    let center = CGPoint(x: canvasSizeF / 2, y: canvasSizeF / 2)
    // ~4% margin from the canvas edge to the tile edge, matching the
    // standard macOS app-icon full-bleed tile proportions.
    let half = canvasSizeF * 0.48
    let tile = squirclePath(center: center, halfWidth: half, halfHeight: half, exponent: 5.0)

    // Clip to the tile, then fill with a vertical gradient (top = bright, bottom = deep).
    context.saveGState()
    context.addPath(tile)
    context.clip()

    let gradientColors: [CGFloat] = [
        palette.top.r, palette.top.g, palette.top.b, 1.0,
        palette.bottom.r, palette.bottom.g, palette.bottom.b, 1.0,
    ]
    guard let gradient = CGGradient(colorSpace: colorSpace, colorComponents: gradientColors, locations: [0.0, 1.0], count: 2) else { return nil }
    let top = CGPoint(x: center.x, y: center.y + half)
    let bottom = CGPoint(x: center.x, y: center.y - half)
    context.drawLinearGradient(gradient, start: top, end: bottom, options: [])

    // Subtle soft highlight near the top of the tile for depth.
    let highlightColors: [CGFloat] = [1.0, 1.0, 1.0, 0.16, 1.0, 1.0, 1.0, 0.0]
    if let highlightGradient = CGGradient(colorSpace: colorSpace, colorComponents: highlightColors, locations: [0.0, 1.0], count: 2) {
        let hTop = CGPoint(x: center.x, y: center.y + half)
        let hEnd = CGPoint(x: center.x, y: center.y + half * 0.15)
        context.drawLinearGradient(highlightGradient, start: hTop, end: hEnd, options: [])
    }

    context.restoreGState()

    // Glyph: white hop arc, centered, ~62% of the tile diameter.
    let glyphSize = (half * 2) * 0.62
    let glyph = buildGlyph(center: center, glyphSize: glyphSize)
    let white = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

    context.saveGState()
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(white)
    context.setLineWidth(glyph.arcWidth)
    context.addPath(glyph.arcPath)
    context.strokePath()

    context.setLineWidth(glyph.ringWidth)
    context.addPath(glyph.ringPath)
    context.strokePath()

    context.setFillColor(white)
    context.addPath(glyph.fillPath)
    context.fillPath()
    context.restoreGState()

    return context.makeImage()
}

func writePNG(_ image: CGImage, to path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        return false
    }
    CGImageDestinationAddImage(destination, image, nil)
    return CGImageDestinationFinalize(destination)
}

// MARK: - Main

var failures = 0
for palette in palettes {
    guard let image = renderIcon(palette: palette) else {
        FileHandle.standardError.write("Failed to render palette \(palette.name)\n".data(using: .utf8)!)
        failures += 1
        continue
    }
    let outputPath = "hop-icon-\(palette.name)-1024.png"
    if writePNG(image, to: outputPath) {
        print("Wrote \(outputPath)")
    } else {
        FileHandle.standardError.write("Failed to write \(outputPath)\n".data(using: .utf8)!)
        failures += 1
    }
}

if failures > 0 {
    exit(1)
}
