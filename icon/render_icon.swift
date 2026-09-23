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
// gradient. Centered on the tile is a custom routing-fork glyph: a vertical
// stroke that forks into two diverging branches, each ending in a filled
// triangular arrowhead. Every path below is drawn by hand with CGMutablePath;
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

// MARK: - Routing-fork glyph (original artwork, not a system symbol)

// Built entirely from custom bezier paths: one trunk stroke, two branch
// strokes, two filled arrowhead triangles. Coordinates are defined in a
// local -0.5...0.5 unit box, then scaled/translated onto the tile.
struct GlyphPaths {
    let strokePath: CGPath
    let strokeWidth: CGFloat
    let arrowheadPath: CGPath
}

func buildGlyph(center: CGPoint, glyphSize: CGFloat) -> GlyphPaths {
    // Local-space key points (unit box, y up).
    let stemBottom = Vec(x: 0.0, y: -0.46)
    let forkPoint = Vec(x: 0.0, y: -0.02)
    let leftEnd = Vec(x: -0.34, y: 0.44)
    let rightEnd = Vec(x: 0.34, y: 0.44)

    func toCanvas(_ v: Vec) -> CGPoint {
        CGPoint(x: center.x + v.x * glyphSize, y: center.y + v.y * glyphSize)
    }

    // Trunk + both branches as one continuous stroke path so the fork reads
    // as a single rounded joint rather than two separate lines glued together.
    let stroke = CGMutablePath()
    stroke.move(to: toCanvas(stemBottom))
    stroke.addLine(to: toCanvas(forkPoint))
    stroke.addLine(to: toCanvas(leftEnd))
    stroke.move(to: toCanvas(forkPoint))
    stroke.addLine(to: toCanvas(rightEnd))

    let strokeWidth = glyphSize * 0.115

    // Arrowheads: filled triangles at each branch end, pointing outward
    // along that branch's direction.
    func arrowhead(end: Vec, from: Vec) -> CGPath {
        let dir = (end - from).normalized
        let perp = dir.perpendicular
        // Fractions of the local unit box (not canvas pixels); toCanvas
        // below applies the glyphSize scale once, at the very end.
        let length: CGFloat = 0.24
        let halfWidth: CGFloat = 0.155
        // Pull the arrowhead back so its base sits well behind the branch
        // end and flares wider than the stroke, reading as a clear triangle
        // rather than a rounded line cap.
        let base = end - dir * (length * 0.55)
        let apex = base + dir * length
        let baseLeft = base + perp * halfWidth
        let baseRight = base - perp * halfWidth

        // These are still local unit-space vectors; project each vertex
        // through the same center/scale transform used for the stroke.
        let tri = CGMutablePath()
        tri.move(to: toCanvas(apex))
        tri.addLine(to: toCanvas(baseLeft))
        tri.addLine(to: toCanvas(baseRight))
        tri.closeSubpath()
        return tri
    }

    let arrowheads = CGMutablePath()
    arrowheads.addPath(arrowhead(end: leftEnd, from: forkPoint))
    arrowheads.addPath(arrowhead(end: rightEnd, from: forkPoint))

    return GlyphPaths(strokePath: stroke, strokeWidth: strokeWidth, arrowheadPath: arrowheads)
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

    // Glyph: white routing fork, centered, ~57% of the tile diameter.
    let glyphSize = (half * 2) * 0.57
    let glyph = buildGlyph(center: center, glyphSize: glyphSize)

    context.saveGState()
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setLineWidth(glyph.strokeWidth)
    context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
    context.addPath(glyph.strokePath)
    context.strokePath()

    context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
    context.addPath(glyph.arrowheadPath)
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
