#!/usr/bin/env swift

// Generates app icon PNGs for the Speech to Text macOS app.
// Uses CoreGraphics to draw a gradient rounded-rect with an SF Symbol waveform.
// Outputs to SpeechToText/Resources/Assets.xcassets/AppIcon.appiconset/

import AppKit
import Foundation

let sizes = [16, 32, 64, 128, 256, 512, 1024]
let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
let projectDir = scriptDir.deletingLastPathComponent()
let outputDir = projectDir
    .appendingPathComponent("SpeechToText/Resources/Assets.xcassets/AppIcon.appiconset")

// Create output directory
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

// Generate 1024x1024 base image
func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // Rounded rect path (macOS icon shape: ~22.37% corner radius)
    let cornerRadius = s * 0.2237
    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Gradient background: deep blue to teal
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(colorSpace: colorSpace, components: [0.1, 0.15, 0.4, 1.0])!,
        CGColor(colorSpace: colorSpace, components: [0.0, 0.6, 0.7, 1.0])!,
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: s),
                               end: CGPoint(x: s, y: 0),
                               options: [])
    }
    ctx.restoreGState()

    // Draw waveform SF Symbol
    if let symbolImage = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil) {
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: s * 0.45, weight: .medium)
        let configured = symbolImage.withSymbolConfiguration(symbolConfig)!

        let symbolSize = configured.size
        let x = (s - symbolSize.width) / 2
        let y = (s - symbolSize.height) / 2

        // Draw white symbol
        let tinted = NSImage(size: symbolSize)
        tinted.lockFocus()
        NSColor.white.set()
        configured.draw(in: NSRect(origin: .zero, size: symbolSize),
                       from: .zero,
                       operation: .sourceOver,
                       fraction: 1.0)
        NSRect(origin: .zero, size: symbolSize).fill(using: .sourceIn)
        tinted.unlockFocus()

        tinted.draw(in: NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height),
                   from: .zero,
                   operation: .sourceOver,
                   fraction: 0.95)
    }

    image.unlockFocus()
    return image
}

// Generate the base 1024x1024 icon
let baseIcon = generateIcon(size: 1024)

// Save 1024 version
let base1024URL = outputDir.appendingPathComponent("icon_1024x1024.png")
if let tiffData = baseIcon.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    try pngData.write(to: base1024URL)
    print("Generated: icon_1024x1024.png")
}

// Use sips to resize to other sizes
for size in sizes where size != 1024 {
    let filename = "icon_\(size)x\(size).png"
    let destURL = outputDir.appendingPathComponent(filename)

    // Copy 1024 version then resize with sips
    try FileManager.default.copyItem(at: base1024URL, to: destURL)

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    process.arguments = ["-z", "\(size)", "\(size)", destURL.path]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try process.run()
    process.waitUntilExit()

    print("Generated: \(filename)")
}

print("\nAll \(sizes.count) icon sizes generated in:")
print(outputDir.path)
