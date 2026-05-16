import AppKit
import Combine

@MainActor
final class StatusBarController {
  private let statusItem: NSStatusItem
  private let view: StatusBarView
  private let menu: NSMenu
  private let cpuItem = NSMenuItem(title: "CPU  —", action: nil, keyEquivalent: "")
  private let gpuItem = NSMenuItem(title: "GPU  —", action: nil, keyEquivalent: "")
  private let ramItem = NSMenuItem(title: "RAM  —", action: nil, keyEquivalent: "")
  private let oneSecondItem = NSMenuItem(title: "1 second", action: nil, keyEquivalent: "")
  private let twoSecondsItem = NSMenuItem(title: "2 seconds", action: nil, keyEquivalent: "")
  private let preferences: Preferences

  init(preferences: Preferences) {
    self.preferences = preferences
    self.statusItem = NSStatusBar.system.statusItem(withLength: StatusBarView.preferredWidth)
    self.view = StatusBarView(frame: NSRect(x: 0, y: 0, width: StatusBarView.preferredWidth, height: NSStatusBar.system.thickness))
    self.menu = NSMenu(title: "Chipbar")

    statusItem.button?.addSubview(view)
    view.frame = statusItem.button?.bounds ?? view.frame
    view.autoresizingMask = [.width, .height]

    buildMenu()
    statusItem.menu = menu
    refreshIntervalChecks()
  }

  func update(with snapshot: Snapshot) {
    view.update(with: snapshot)
    cpuItem.title = "CPU  \(percent(snapshot.cpu))"
    gpuItem.title = "GPU  \(percent(snapshot.gpu))"
    ramItem.title = "RAM  \(percent(snapshot.ram))"
  }

  func refreshIntervalChecks() {
    oneSecondItem.state = preferences.refreshIntervalSeconds == 1 ? .on : .off
    twoSecondsItem.state = preferences.refreshIntervalSeconds == 2 ? .on : .off
  }

  private func buildMenu() {
    cpuItem.isEnabled = false
    gpuItem.isEnabled = false
    ramItem.isEnabled = false

    menu.addItem(cpuItem)
    menu.addItem(gpuItem)
    menu.addItem(ramItem)
    menu.addItem(.separator())

    let updateEvery = NSMenuItem(title: "Update every", action: nil, keyEquivalent: "")
    let submenu = NSMenu(title: "Update every")
    oneSecondItem.target = self
    oneSecondItem.action = #selector(selectOneSecond)
    twoSecondsItem.target = self
    twoSecondsItem.action = #selector(selectTwoSeconds)
    submenu.addItem(oneSecondItem)
    submenu.addItem(twoSecondsItem)
    updateEvery.submenu = submenu
    menu.addItem(updateEvery)

    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: "Quit Chip Bar", action: #selector(quit), keyEquivalent: "q"))
    menu.items.last?.target = self
  }

  @objc private func selectOneSecond() {
    preferences.refreshIntervalSeconds = 1
    refreshIntervalChecks()
  }

  @objc private func selectTwoSeconds() {
    preferences.refreshIntervalSeconds = 2
    refreshIntervalChecks()
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }

  private func percent(_ value: Double) -> String {
    "\(Int((value * 100).rounded()))%"
  }
}
