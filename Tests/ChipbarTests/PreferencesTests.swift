import XCTest
import Combine
@testable import Chipbar

final class PreferencesTests: XCTestCase {
  private var defaults: UserDefaults!
  private var suiteName: String!
  private var cancellables: Set<AnyCancellable> = []

  override func setUp() {
    suiteName = "chipbar-tests-\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)!
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
    cancellables.removeAll()
  }

  func test_defaultIsOneSecondWhenKeyMissing() {
    let prefs = Preferences(defaults: defaults)
    XCTAssertEqual(prefs.refreshIntervalSeconds, 1)
  }

  func test_writeAndReadRoundTrip() {
    let prefs = Preferences(defaults: defaults)
    prefs.refreshIntervalSeconds = 2
    XCTAssertEqual(prefs.refreshIntervalSeconds, 2)

    let prefs2 = Preferences(defaults: defaults)
    XCTAssertEqual(prefs2.refreshIntervalSeconds, 2)
  }

  func test_invalidValuesFallBackToOne() {
    defaults.set(0, forKey: "chipbar.refreshIntervalSeconds")
    XCTAssertEqual(Preferences(defaults: defaults).refreshIntervalSeconds, 1)

    defaults.set(3, forKey: "chipbar.refreshIntervalSeconds")
    XCTAssertEqual(Preferences(defaults: defaults).refreshIntervalSeconds, 1)

    defaults.set(-5, forKey: "chipbar.refreshIntervalSeconds")
    XCTAssertEqual(Preferences(defaults: defaults).refreshIntervalSeconds, 1)
  }

  func test_publisherEmitsOnChange() {
    let prefs = Preferences(defaults: defaults)
    let exp = expectation(description: "publisher fired")
    var received: [Int] = []

    prefs.refreshIntervalSecondsPublisher
      .dropFirst() // drop initial value
      .sink { value in
        received.append(value)
        if received == [2] { exp.fulfill() }
      }
      .store(in: &cancellables)

    prefs.refreshIntervalSeconds = 2
    wait(for: [exp], timeout: 1.0)
    XCTAssertEqual(received, [2])
  }
}
