import Foundation
import Combine

final class Preferences {
  static let refreshIntervalKey = "chipbar.refreshIntervalSeconds"
  static let allowedIntervals: Set<Int> = [1, 2]
  static let defaultInterval = 1

  private let defaults: UserDefaults
  private let subject: CurrentValueSubject<Int, Never>

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    let raw = defaults.object(forKey: Self.refreshIntervalKey) as? Int
    let initial: Int
    if let raw, Self.allowedIntervals.contains(raw) {
      initial = raw
    } else {
      initial = Self.defaultInterval
    }
    self.subject = CurrentValueSubject(initial)
  }

  var refreshIntervalSeconds: Int {
    get { subject.value }
    set {
      let value = Self.allowedIntervals.contains(newValue) ? newValue : Self.defaultInterval
      defaults.set(value, forKey: Self.refreshIntervalKey)
      subject.send(value)
    }
  }

  var refreshIntervalSecondsPublisher: AnyPublisher<Int, Never> {
    subject.eraseToAnyPublisher()
  }
}
