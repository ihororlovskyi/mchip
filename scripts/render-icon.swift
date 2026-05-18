#!/usr/bin/env swift
import AppKit
import Foundation

let outputDir = CommandLine.arguments.count > 1
  ? CommandLine.arguments[1]
  : "assets/AppIcon.iconset"

let topColor = NSColor(red: 0xE6 / 255.0, green: 0xE4 / 255.0, blue: 0xDD / 255.0, alpha: 1.0)
let bottomColor = NSColor(red: 0xE3 / 255.0, green: 0xE2 / 255.0, blue: 0xDA / 255.0, alpha: 1.0)
let textColor = NSColor(red: 0x1D / 255.0, green: 0x1D / 255.0, blue: 0x1F / 255.0, alpha: 1.0)

try? FileManager.default.createDirectory(
  atPath: outputDir, withIntermediateDirectories: true
)

func renderPNG(size: Int) -> Data? {
  guard
    let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: size,
      pixelsHigh: size,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    )
  else { return nil }

  NSGraphicsContext.saveGraphicsState()
  defer { NSGraphicsContext.restoreGraphicsState() }
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

  let s = CGFloat(size)
  let rect = NSRect(x: 0, y: 0, width: s, height: s)
  let cornerRadius = s * 0.225
  let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
  path.addClip()

  let gradient = NSGradient(starting: topColor, ending: bottomColor)!
  gradient.draw(in: rect, angle: 270)

  let font = NSFont.systemFont(ofSize: s * 0.7, weight: .black)
  let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: textColor,
  ]
  let text = NSAttributedString(string: "m", attributes: attrs)
  let textSize = text.size()
  let origin = NSPoint(
    x: (s - textSize.width) / 2.0,
    y: (s - textSize.height) / 2.0 - s * 0.03
  )
  text.draw(at: origin)

  return bitmap.representation(using: .png, properties: [:])
}

let mapping: [(name: String, size: Int)] = [
  ("icon_16x16.png", 16),
  ("icon_16x16@2x.png", 32),
  ("icon_32x32.png", 32),
  ("icon_32x32@2x.png", 64),
  ("icon_128x128.png", 128),
  ("icon_128x128@2x.png", 256),
  ("icon_256x256.png", 256),
  ("icon_256x256@2x.png", 512),
  ("icon_512x512.png", 512),
  ("icon_512x512@2x.png", 1024),
]

for entry in mapping {
  guard let png = renderPNG(size: entry.size) else {
    fputs("failed to render \(entry.name)\n", stderr)
    exit(1)
  }
  let url = URL(fileURLWithPath: outputDir).appendingPathComponent(entry.name)
  do {
    try png.write(to: url)
    print("wrote \(url.lastPathComponent) (\(entry.size)x\(entry.size))")
  } catch {
    fputs("failed to write \(url.path): \(error)\n", stderr)
    exit(1)
  }
}
