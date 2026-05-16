import AppKit

@MainActor
final class StatusBarView: NSView {
  static let preferredWidth: CGFloat = 64

  private var snapshot: Snapshot = .zero
  private let iconFont = NSFont.systemFont(ofSize: 8, weight: .regular)
  private let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular)

  override var intrinsicContentSize: NSSize {
    NSSize(width: Self.preferredWidth, height: NSStatusBar.system.thickness)
  }

  func update(with snapshot: Snapshot) {
    self.snapshot = snapshot
    needsDisplay = true
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let cellWidth = bounds.width / 3
    let cells = [
      ("cpu", snapshot.cpu, NSRect(x: 0,             y: 0, width: cellWidth, height: bounds.height)),
      ("gpu.fill", snapshot.gpu, NSRect(x: cellWidth,   y: 0, width: cellWidth, height: bounds.height)),
      ("memorychip", snapshot.ram, NSRect(x: cellWidth*2, y: 0, width: cellWidth, height: bounds.height)),
    ]

    for (symbolName, value, frame) in cells {
      drawCell(symbolName: symbolName, value: value, in: frame)
    }
  }

  private func drawCell(symbolName: String, value: Double, in rect: NSRect) {
    let percent = Int((value * 100).rounded())
    let valueString = "\(percent)%"

    let valueAttrs: [NSAttributedString.Key: Any] = [
      .font: valueFont,
      .foregroundColor: NSColor.labelColor,
    ]
    let valueAS = NSAttributedString(string: valueString, attributes: valueAttrs)
    let valueSize = valueAS.size()

    let iconConfig = NSImage.SymbolConfiguration(pointSize: 9, weight: .regular)
    let icon = NSImage(systemSymbolName: symbolName, accessibilityDescription: symbolName)?
      .withSymbolConfiguration(iconConfig)

    let iconHeight: CGFloat = 9
    let totalHeight = iconHeight + 1 + valueSize.height
    let originY = (rect.height - totalHeight) / 2

    if let icon {
      let iconRect = NSRect(
        x: rect.midX - icon.size.width / 2,
        y: originY + valueSize.height + 1,
        width: icon.size.width,
        height: iconHeight
      )
      icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    let valueRect = NSRect(
      x: rect.midX - valueSize.width / 2,
      y: originY,
      width: valueSize.width,
      height: valueSize.height
    )
    valueAS.draw(in: valueRect)
  }
}
