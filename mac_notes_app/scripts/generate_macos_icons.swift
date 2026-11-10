/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Native macOS CoreGraphics/AppKit vector generator for the Minimalist Dark/Amber AppIcon set (16px to 1024px) and Flutter in-app icon asset.
 */

import AppKit
import CoreGraphics
import Foundation

/// Configuration for an individual icon output target.
struct IconTarget {
    let filename: String
    let size: Int
}

/// Renders the Minimalist Dark/Amber Notes icon at the specified pixel dimension.
func renderIcon(size: Int) -> NSBitmapImageRep? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: size * 4,
        bitsPerPixel: 32
    ) else {
        return nil
    }

    NSGraphicsContext.saveGraphicsState()
    guard let nsContext = NSGraphicsContext(bitmapImageRep: rep) else {
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }
    NSGraphicsContext.current = nsContext
    let cg = nsContext.cgContext

    cg.setAllowsAntialiasing(true)
    cg.setShouldAntialias(true)
    cg.interpolationQuality = .high

    // Normalize coordinate space to a 1024x1024 master canvas (y=0 at bottom, y=1024 at top)
    let scale = CGFloat(size) / 1024.0
    cg.scaleBy(x: scale, y: scale)

    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // Helper to create CGColor from 0..255 RGB + alpha
    func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> CGColor {
        return CGColor(colorSpace: colorSpace, components: [r / 255.0, g / 255.0, b / 255.0, a])!
    }

    // Helper to apply scale-aware shadow in device pixel space
    func setScaledShadow(dx: CGFloat, dy: CGFloat, blur: CGFloat, color: CGColor) {
        cg.setShadow(
            offset: CGSize(width: dx * scale, height: dy * scale),
            blur: blur * scale,
            color: color
        )
    }

    // 1. macOS Continuous Squircle Geometry (824x824 centered in 1024x1024)
    let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
    let squircleRadius: CGFloat = 185.4
    let squirclePath = CGPath(
        roundedRect: squircleRect,
        cornerWidth: squircleRadius,
        cornerHeight: squircleRadius,
        transform: nil
    )

    // Outer drop shadow under the macOS squircle
    cg.saveGState()
    setScaledShadow(dx: 0, dy: -18, blur: 36, color: rgba(0, 0, 0, 0.50))
    cg.setFillColor(rgba(16, 16, 20, 1.0))
    cg.addPath(squirclePath)
    cg.fillPath()
    cg.restoreGState()

    // Clip to squircle for internal background, glow, and rim
    cg.saveGState()
    cg.addPath(squirclePath)
    cg.clip()

    // Deep charcoal-obsidian diagonal gradient fill
    let bgColors = [
        rgba(38, 38, 46, 1.0),
        rgba(20, 20, 26, 1.0),
        rgba(10, 10, 14, 1.0),
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.52, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        cg.drawLinearGradient(
            bgGradient,
            start: CGPoint(x: 140, y: 900),
            end: CGPoint(x: 880, y: 120),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }

    // Ambient radial amber (#ECA825) glow in the center of the dark squircle
    let glowColors = [
        rgba(236, 168, 37, 0.28),
        rgba(236, 168, 37, 0.10),
        rgba(236, 168, 37, 0.0),
    ] as CFArray
    let glowLocations: [CGFloat] = [0.0, 0.55, 1.0]
    if let radialGlow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: glowLocations) {
        cg.drawRadialGradient(
            radialGlow,
            startCenter: CGPoint(x: 495, y: 515),
            startRadius: 20,
            endCenter: CGPoint(x: 495, y: 515),
            endRadius: 430,
            options: [.drawsAfterEndLocation]
        )
    }

    // Subtle top-left warm glass sheen
    let sheenColors = [
        rgba(255, 255, 255, 0.07),
        rgba(255, 255, 255, 0.0),
    ] as CFArray
    if let sheenGrad = CGGradient(colorsSpace: colorSpace, colors: sheenColors, locations: [0.0, 1.0]) {
        cg.drawLinearGradient(
            sheenGrad,
            start: CGPoint(x: 100, y: 924),
            end: CGPoint(x: 512, y: 512),
            options: []
        )
    }

    // 2. Minimalist Glowing Note Card Emblem
    let noteRect = CGRect(x: 266, y: 230, width: 432, height: 550)
    let noteRadius: CGFloat = 58.0
    let notePath = CGPath(
        roundedRect: noteRect,
        cornerWidth: noteRadius,
        cornerHeight: noteRadius,
        transform: nil
    )

    // Outer ambient amber glow + shadow around the note card
    cg.saveGState()
    setScaledShadow(dx: 0, dy: -12, blur: 48, color: rgba(236, 168, 37, 0.45))
    cg.setFillColor(rgba(22, 22, 28, 1.0))
    cg.addPath(notePath)
    cg.fillPath()
    cg.restoreGState()

    // Note card body fill (sleek dark elevated charcoal slate)
    cg.saveGState()
    cg.addPath(notePath)
    cg.clip()

    let cardColors = [
        rgba(34, 34, 42, 1.0),
        rgba(22, 22, 28, 1.0),
        rgba(16, 16, 21, 1.0),
    ] as CFArray
    if let cardGrad = CGGradient(colorsSpace: colorSpace, colors: cardColors, locations: [0.0, 0.6, 1.0]) {
        cg.drawLinearGradient(
            cardGrad,
            start: CGPoint(x: noteRect.minX, y: noteRect.maxY),
            end: CGPoint(x: noteRect.maxX, y: noteRect.minY),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }

    // Signature Apple Notes Amber Header Band clipped strictly to the top of the note card
    let headerHeight: CGFloat = 114.0
    let headerRect = CGRect(
        x: noteRect.minX,
        y: noteRect.maxY - headerHeight,
        width: noteRect.width,
        height: headerHeight
    )
    cg.saveGState()
    cg.clip(to: headerRect)
    let headerColors = [
        rgba(255, 218, 112, 1.0),
        rgba(236, 168, 37, 1.0),
        rgba(212, 136, 6, 1.0),
    ] as CFArray
    if let headerGrad = CGGradient(colorsSpace: colorSpace, colors: headerColors, locations: [0.0, 0.55, 1.0]) {
        cg.drawLinearGradient(
            headerGrad,
            start: CGPoint(x: headerRect.minX, y: headerRect.maxY),
            end: CGPoint(x: headerRect.maxX, y: headerRect.minY),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }
    cg.restoreGState()

    // Crisp luminous separator line directly under the header band
    cg.saveGState()
    setScaledShadow(dx: 0, dy: -2, blur: 12, color: rgba(236, 168, 37, 0.55))
    cg.setStrokeColor(rgba(255, 228, 150, 0.85))
    cg.setLineWidth(3.5)
    cg.move(to: CGPoint(x: noteRect.minX, y: headerRect.minY))
    cg.addLine(to: CGPoint(x: noteRect.maxX, y: headerRect.minY))
    cg.strokePath()
    cg.restoreGState()

    cg.restoreGState() // End note card clip

    // Glowing amber border stroke around the note card
    cg.saveGState()
    setScaledShadow(dx: 0, dy: 0, blur: 18, color: rgba(236, 168, 37, 0.60))
    cg.addPath(notePath)
    cg.setStrokeColor(rgba(236, 168, 37, 0.94))
    cg.setLineWidth(8.5)
    cg.strokePath()
    cg.restoreGState()

    // 3. Glowing Note Lines & Checklist Dot inside the Dark Note Card Body
    func drawGlowingPill(_ rect: CGRect, alpha: CGFloat = 1.0) {
        let pillPath = CGPath(
            roundedRect: rect,
            cornerWidth: rect.height / 2.0,
            cornerHeight: rect.height / 2.0,
            transform: nil
        )
        cg.saveGState()
        setScaledShadow(dx: 0, dy: 0, blur: 16, color: rgba(236, 168, 37, 0.65 * alpha))
        cg.setFillColor(rgba(236, 168, 37, alpha))
        cg.addPath(pillPath)
        cg.fillPath()
        cg.restoreGState()

        cg.saveGState()
        cg.addPath(pillPath)
        cg.clip()
        let lineColors = [
            rgba(255, 228, 142, alpha),
            rgba(236, 168, 37, alpha),
        ] as CFArray
        if let lineGrad = CGGradient(colorsSpace: colorSpace, colors: lineColors, locations: [0.0, 1.0]) {
            cg.drawLinearGradient(
                lineGrad,
                start: CGPoint(x: rect.minX, y: rect.midY),
                end: CGPoint(x: rect.maxX, y: rect.midY),
                options: []
            )
        }
        cg.restoreGState()
    }

    // Row 1: Circular amber checklist ring + top title line
    let row1Y: CGFloat = 556.0
    let bulletCenter = CGPoint(x: 348, y: row1Y + 12)
    cg.saveGState()
    setScaledShadow(dx: 0, dy: 0, blur: 14, color: rgba(236, 168, 37, 0.70))
    cg.setStrokeColor(rgba(255, 220, 118, 0.98))
    cg.setLineWidth(7.5)
    cg.addArc(center: bulletCenter, radius: 15, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    cg.strokePath()
    cg.setFillColor(rgba(236, 168, 37, 0.98))
    cg.addArc(center: bulletCenter, radius: 6.5, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    cg.fillPath()
    cg.restoreGState()

    drawGlowingPill(CGRect(x: 388, y: row1Y, width: 232, height: 24), alpha: 0.98)

    // Row 2: Medium body line
    let row2Y: CGFloat = 466.0
    drawGlowingPill(CGRect(x: 332, y: row2Y, width: 266, height: 22), alpha: 0.88)

    // Row 3: Shorter body line (where the pen nib writes)
    let row3Y: CGFloat = 376.0
    drawGlowingPill(CGRect(x: 332, y: row3Y, width: 168, height: 22), alpha: 0.82)

    // 4. Sleek Glowing Amber Fountain / Stylus Pen Emblem (angled at -42 degrees)
    cg.saveGState()
    let penTip = CGPoint(x: 530, y: 378)
    cg.translateBy(x: penTip.x, y: penTip.y)
    cg.rotate(by: -42.0 * .pi / 180.0)

    let barrelWidth: CGFloat = 54.0
    let halfW = barrelWidth / 2.0
    let nibLength: CGFloat = 68.0
    let collarLength: CGFloat = 22.0
    let bodyLength: CGFloat = 262.0
    let capLength: CGFloat = 46.0

    let fullPenPath = CGMutablePath()
    fullPenPath.move(to: CGPoint(x: 0, y: 0))
    fullPenPath.addLine(to: CGPoint(x: -halfW, y: nibLength))
    fullPenPath.addLine(to: CGPoint(x: -halfW, y: nibLength + collarLength + bodyLength))
    fullPenPath.addArc(
        center: CGPoint(x: 0, y: nibLength + collarLength + bodyLength),
        radius: halfW,
        startAngle: .pi,
        endAngle: 0,
        clockwise: true
    )
    fullPenPath.addLine(to: CGPoint(x: halfW, y: nibLength))
    fullPenPath.closeSubpath()

    // Deep drop shadow cast by the pen onto the dark note card
    cg.saveGState()
    setScaledShadow(dx: -12, dy: -16, blur: 30, color: rgba(0, 0, 0, 0.78))
    cg.setFillColor(rgba(20, 20, 25, 1.0))
    cg.addPath(fullPenPath)
    cg.fillPath()
    cg.restoreGState()

    // Warm amber outer glow around the pen
    cg.saveGState()
    setScaledShadow(dx: 0, dy: 0, blur: 24, color: rgba(236, 168, 37, 0.60))
    cg.setFillColor(rgba(236, 168, 37, 0.25))
    cg.addPath(fullPenPath)
    cg.fillPath()
    cg.restoreGState()

    // A. Nib cone (0 to nibLength)
    let nibPath = CGMutablePath()
    nibPath.move(to: CGPoint(x: 0, y: 0))
    nibPath.addLine(to: CGPoint(x: -halfW, y: nibLength))
    nibPath.addLine(to: CGPoint(x: halfW, y: nibLength))
    nibPath.closeSubpath()

    cg.saveGState()
    cg.addPath(nibPath)
    cg.clip()
    let nibColors = [
        rgba(255, 242, 195, 1.0),
        rgba(236, 168, 37, 1.0),
        rgba(196, 124, 8, 1.0),
    ] as CFArray
    if let nibGrad = CGGradient(colorsSpace: colorSpace, colors: nibColors, locations: [0.0, 0.5, 1.0]) {
        cg.drawLinearGradient(
            nibGrad,
            start: CGPoint(x: -halfW, y: nibLength * 0.5),
            end: CGPoint(x: halfW, y: nibLength * 0.5),
            options: []
        )
    }
    // Luminous gold tip point at the very end (0..18)
    cg.setFillColor(rgba(255, 248, 220, 1.0))
    cg.fill(CGRect(x: -halfW, y: 0, width: barrelWidth, height: 18))
    cg.restoreGState()

    // B. Dark Charcoal Collar Band
    let collarRect = CGRect(x: -halfW, y: nibLength, width: barrelWidth, height: collarLength)
    cg.setFillColor(rgba(20, 20, 26, 1.0))
    cg.fill(collarRect)

    // C. Main Glowing Amber Barrel
    let bodyRect = CGRect(
        x: -halfW,
        y: nibLength + collarLength,
        width: barrelWidth,
        height: bodyLength
    )
    cg.saveGState()
    cg.clip(to: bodyRect)
    let barrelColors = [
        rgba(255, 230, 145, 1.0),
        rgba(236, 168, 37, 1.0),
        rgba(184, 114, 4, 1.0),
    ] as CFArray
    if let barrelGrad = CGGradient(colorsSpace: colorSpace, colors: barrelColors, locations: [0.0, 0.45, 1.0]) {
        cg.drawLinearGradient(
            barrelGrad,
            start: CGPoint(x: -halfW, y: bodyRect.midY),
            end: CGPoint(x: halfW, y: bodyRect.midY),
            options: []
        )
    }
    cg.restoreGState()

    // D. Rounded Top Cap
    let capStartY = nibLength + collarLength + bodyLength
    let capPath = CGMutablePath()
    capPath.move(to: CGPoint(x: -halfW, y: capStartY))
    capPath.addArc(
        center: CGPoint(x: 0, y: capStartY),
        radius: halfW,
        startAngle: .pi,
        endAngle: 0,
        clockwise: true
    )
    capPath.closeSubpath()

    cg.saveGState()
    cg.addPath(capPath)
    cg.clip()
    let capColors = [
        rgba(255, 238, 175, 1.0),
        rgba(236, 168, 37, 1.0),
    ] as CFArray
    if let capGrad = CGGradient(colorsSpace: colorSpace, colors: capColors, locations: [0.0, 1.0]) {
        cg.drawLinearGradient(
            capGrad,
            start: CGPoint(x: -halfW, y: capStartY),
            end: CGPoint(x: halfW, y: capStartY + capLength),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }
    cg.restoreGState()

    // Dark separator ring just below the cap
    cg.setFillColor(rgba(20, 20, 26, 0.95))
    cg.fill(CGRect(x: -halfW, y: capStartY - 10, width: barrelWidth, height: 10))

    // Crisp specular edge highlight on the pen
    cg.setStrokeColor(rgba(255, 242, 195, 0.78))
    cg.setLineWidth(3.2)
    cg.addPath(fullPenPath)
    cg.strokePath()

    cg.restoreGState() // End pen transform

    // 5. Inner Rim Highlight around the macOS Squircle
    let insetSquircleRect = squircleRect.insetBy(dx: 2.5, dy: 2.5)
    let insetSquirclePath = CGPath(
        roundedRect: insetSquircleRect,
        cornerWidth: squircleRadius - 2.5,
        cornerHeight: squircleRadius - 2.5,
        transform: nil
    )
    cg.setStrokeColor(rgba(236, 168, 37, 0.34))
    cg.setLineWidth(4.5)
    cg.addPath(insetSquirclePath)
    cg.strokePath()

    cg.restoreGState() // End squircle clip
    NSGraphicsContext.restoreGraphicsState()

    return rep
}

/// Writes a rendered icon PNG to disk.
func writeIcon(size: Int, to url: URL) throws {
    guard let rep = renderIcon(size: size),
          let pngData = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to render \(size)x\(size) icon"])
    }
    try pngData.write(to: url, options: .atomic)
}

let fileManager = FileManager.default
let projectRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let appIconSetDir = projectRoot.appendingPathComponent("macos/Runner/Assets.xcassets/AppIcon.appiconset")
let flutterIconDir = projectRoot.appendingPathComponent("assets/icons")

try fileManager.createDirectory(at: appIconSetDir, withIntermediateDirectories: true)
try fileManager.createDirectory(at: flutterIconDir, withIntermediateDirectories: true)

let targets: [IconTarget] = [
    IconTarget(filename: "app_icon_16.png", size: 16),
    IconTarget(filename: "app_icon_32.png", size: 32),
    IconTarget(filename: "app_icon_64.png", size: 64),
    IconTarget(filename: "app_icon_128.png", size: 128),
    IconTarget(filename: "app_icon_256.png", size: 256),
    IconTarget(filename: "app_icon_512.png", size: 512),
    IconTarget(filename: "app_icon_1024.png", size: 1024),
]

for target in targets {
    let destURL = appIconSetDir.appendingPathComponent(target.filename)
    try writeIcon(size: target.size, to: destURL)
    print("Generated \(target.filename) (\(target.size)x\(target.size))")
}

let inAppIconURL = flutterIconDir.appendingPathComponent("app_icon.png")
try writeIcon(size: 512, to: inAppIconURL)
print("Generated assets/icons/app_icon.png (512x512)")
