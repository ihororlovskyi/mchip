import AppKit
import Combine

@MainActor
final class StatusBarController {
  static let repositoryURL = URL(string: "https://github.com/ihororlovskyi/mchip")!

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
    let initialWidth = StatusBarView.width(for: preferences.metricVisibility)
    self.statusItem = NSStatusBar.system.statusItem(withLength: initialWidth)
    self.view = StatusBarView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: NSStatusBar.system.thickness))
    self.menu = NSMenu(title: "mchip")

    statusItem.button?.addSubview(view)
    view.frame = statusItem.button?.bounds ?? view.frame
    view.autoresizingMask = [.width, .height]
    view.update(visibility: preferences.metricVisibility)

    buildMenu()
    statusItem.menu = menu
    refreshIntervalChecks()
    refreshVisibilityChecks()
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

  func refreshVisibilityChecks() {
    let visibility = preferences.metricVisibility
    cpuItem.state = visibility.cpu ? .on : .off
    gpuItem.state = visibility.gpu ? .on : .off
    ramItem.state = visibility.ram ? .on : .off
    view.update(visibility: visibility)
    let width = StatusBarView.width(for: visibility)
    statusItem.length = width
    view.frame = statusItem.button?.bounds ?? NSRect(x: 0, y: 0, width: width, height: NSStatusBar.system.thickness)
  }

  private func buildMenu() {
    cpuItem.target = self
    cpuItem.action = #selector(toggleCPU)
    gpuItem.target = self
    gpuItem.action = #selector(toggleGPU)
    ramItem.target = self
    ramItem.action = #selector(toggleRAM)

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

    let about = NSMenuItem(title: "About", action: nil, keyEquivalent: "")
    about.submenu = makeAboutSubmenu()
    menu.addItem(about)

    menu.addItem(.separator())
    let quit = NSMenuItem(title: "Quit mchip", action: #selector(quitApp), keyEquivalent: "q")
    quit.target = self
    menu.addItem(quit)
  }

  private func makeAboutSubmenu() -> NSMenu {
    let submenu = NSMenu(title: "About")

    let nameItem = NSMenuItem(title: "mchip", action: nil, keyEquivalent: "")
    nameItem.isEnabled = false
    submenu.addItem(nameItem)

    let versionItem = NSMenuItem(title: "v\(Self.appVersion)", action: nil, keyEquivalent: "")
    versionItem.isEnabled = false
    submenu.addItem(versionItem)

    let dateItem = NSMenuItem(title: Self.buildDateString, action: nil, keyEquivalent: "")
    dateItem.isEnabled = false
    submenu.addItem(dateItem)

    let github = NSMenuItem(title: "GitHub", action: #selector(openRepository), keyEquivalent: "")
    github.target = self
    submenu.addItem(github)

    return submenu
  }

  private static var appVersion: String {
    (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
  }

  private static var buildDateString: String {
    let url = Bundle.main.executableURL ?? Bundle.main.bundleURL
    let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
    let date = (attrs?[.modificationDate] as? Date) ?? Date()
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "dd MMM yy"
    return formatter.string(from: date)
  }

  @objc private func openRepository() {
    NSWorkspace.shared.open(Self.repositoryURL)
  }

  @objc private func toggleCPU() { toggle(.cpu, item: cpuItem) }
  @objc private func toggleGPU() { toggle(.gpu, item: gpuItem) }
  @objc private func toggleRAM() { toggle(.ram, item: ramItem) }

  private func toggle(_ metric: Preferences.Metric, item: NSMenuItem) {
    let nextVisible = item.state != .on
    if preferences.setMetricVisible(metric, nextVisible) {
      refreshVisibilityChecks()
    } else {
      NSSound.beep()
    }
  }

  @objc private func selectOneSecond() {
    preferences.refreshIntervalSeconds = 1
    refreshIntervalChecks()
  }

  @objc private func selectTwoSeconds() {
    preferences.refreshIntervalSeconds = 2
    refreshIntervalChecks()
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }

  private func percent(_ value: Double) -> String {
    "\(Int((value * 100).rounded()))%"
  }
}
