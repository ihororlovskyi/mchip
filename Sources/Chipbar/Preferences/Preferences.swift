import Foundation
import Combine

struct MetricVisibility: Equatable, Sendable {
  var cpu: Bool
  var gpu: Bool
  var ram: Bool

  static let allOn = MetricVisibility(cpu: true, gpu: true, ram: true)

  var visibleCount: Int {
    (cpu ? 1 : 0) + (gpu ? 1 : 0) + (ram ? 1 : 0)
  }
}

final class Preferences {
  static let refreshIntervalKey = "chipbar.refreshIntervalSeconds"
  static let allowedIntervals: Set<Int> = [1, 2]
  static let defaultInterval = 1

  static let showCPUKey = "chipbar.show.cpu"
  static let showGPUKey = "chipbar.show.gpu"
  static let showRAMKey = "chipbar.show.ram"

  private let defaults: UserDefaults
  private let intervalSubject: CurrentValueSubject<Int, Never>
  private let visibilitySubject: CurrentValueSubject<MetricVisibility, Never>

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults

    let raw = defaults.object(forKey: Self.refreshIntervalKey) as? Int
    let initialInterval: Int
    if let raw, Self.allowedIntervals.contains(raw) {
      initialInterval = raw
    } else {
      initialInterval = Self.defaultInterval
    }
    self.intervalSubject = CurrentValueSubject(initialInterval)

    let initialVisibility = MetricVisibility(
      cpu: Self.loadFlag(defaults: defaults, key: Self.showCPUKey),
      gpu: Self.loadFlag(defaults: defaults, key: Self.showGPUKey),
      ram: Self.loadFlag(defaults: defaults, key: Self.showRAMKey)
    )
    self.visibilitySubject = CurrentValueSubject(
      initialVisibility.visibleCount == 0 ? .allOn : initialVisibility
    )
  }

  var refreshIntervalSeconds: Int {
    get { intervalSubject.value }
    set {
      let value = Self.allowedIntervals.contains(newValue) ? newValue : Self.defaultInterval
      defaults.set(value, forKey: Self.refreshIntervalKey)
      intervalSubject.send(value)
    }
  }

  var refreshIntervalSecondsPublisher: AnyPublisher<Int, Never> {
    intervalSubject.eraseToAnyPublisher()
  }

  var metricVisibility: MetricVisibility {
    visibilitySubject.value
  }

  var metricVisibilityPublisher: AnyPublisher<MetricVisibility, Never> {
    visibilitySubject.eraseToAnyPublisher()
  }

  @discardableResult
  func setMetricVisible(_ metric: Metric, _ visible: Bool) -> Bool {
    var next = visibilitySubject.value
    switch metric {
    case .cpu: next.cpu = visible
    case .gpu: next.gpu = visible
    case .ram: next.ram = visible
    }
    if next.visibleCount == 0 { return false }
    defaults.set(next.cpu, forKey: Self.showCPUKey)
    defaults.set(next.gpu, forKey: Self.showGPUKey)
    defaults.set(next.ram, forKey: Self.showRAMKey)
    visibilitySubject.send(next)
    return true
  }

  enum Metric {
    case cpu, gpu, ram
  }

  private static func loadFlag(defaults: UserDefaults, key: String) -> Bool {
    if defaults.object(forKey: key) == nil { return true }
    return defaults.bool(forKey: key)
  }
}
