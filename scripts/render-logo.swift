#!/usr/bin/env swift
import AppKit

let pixelsWide = 1280
let pixelsHigh = 640

let topColor = NSColor(red: 0xE6 / 255.0, green: 0xE4 / 255.0, blue: 0xDD / 255.0, alpha: 1.0)
let bottomColor = NSColor(red: 0xE3 / 255.0, green: 0xE2 / 255.0, blue: 0xDA / 255.0, alpha: 1.0)
let textColor = NSColor(red: 0x1D / 255.0, green: 0x1D / 255.0, blue: 0x1F / 255.0, alpha: 1.0)

guard let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: pixelsWide,
  pixelsHigh: pixelsHigh,
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: 0,
  bitsPerPixel: 0
) else {
  fputs("failed to create bitmap rep\n", stderr)
  exit(1)
}

NSGraphicsContext.saveGraphicsState()
defer { NSGraphicsContext.restoreGraphicsState() }
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let canvas = NSRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh)

let gradient = NSGradient(starting: topColor, ending: bottomColor)!
gradient.draw(in: canvas, angle: 270)

let fontSize: CGFloat = 280
let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
  .font: font,
  .foregroundColor: textColor,
  .paragraphStyle: paragraph,
  .kern: 2.0,
]
let text = NSAttributedString(string: "mchip", attributes: attrs)
let textSize = text.size()
let origin = NSPoint(
  x: (CGFloat(pixelsWide) - textSize.width) / 2.0,
  y: (CGFloat(pixelsHigh) - textSize.height) / 2.0
)
text.draw(at: origin)

guard
  let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92])
else {
  fputs("failed to encode JPEG\n", stderr)
  exit(1)
}

let outputPath = CommandLine.arguments.count > 1
  ? CommandLine.arguments[1]
  : "assets/img/mchip-logo.jpg"

do {
  try data.write(to: URL(fileURLWithPath: outputPath))
  print("wrote \(outputPath) (\(pixelsWide)x\(pixelsHigh))")
} catch {
  fputs("failed to write: \(error)\n", stderr)
  exit(1)
}
