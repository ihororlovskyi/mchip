import Foundation

protocol GPUReading {
  /// Returns GPU utilisation in the range 0.0...1.0.
  func sample() -> Double
}

final class MockGPUReader: GPUReading {
  private let samples: () -> Double
  init(samples: @escaping () -> Double) { self.samples = samples }
  func sample() -> Double { samples() }
}

// MARK: - IOReport implementation

/// Reads Apple Silicon GPU busy ratio from the private IOReport framework.
/// Same approach used by Stats.app, asitop, mactop. First sample after init returns 0.0.
final class GPUReader: GPUReading {
  private let bridge: IOReportBridgeProtocol
  private var previousActive: Int64 = 0
  private var previousTotal: Int64 = 0
  private var primed = false

  init(bridge: IOReportBridgeProtocol) {
    self.bridge = bridge
  }

  /// Returns nil if the IOReport bridge cannot be initialised (e.g. headless CI runner).
  convenience init?() {
    guard let bridge = IOReportBridge() else { return nil }
    self.init(bridge: bridge)
  }

  func sample() -> Double {
    let raw = bridge.readGPUResidency()
    defer {
      previousActive = raw.active
      previousTotal = raw.total
      primed = true
    }
    guard primed else { return 0.0 }
    let activeDelta = raw.active - previousActive
    let totalDelta = raw.total - previousTotal
    guard totalDelta > 0, activeDelta >= 0 else { return 0.0 }
    return min(1.0, max(0.0, Double(activeDelta) / Double(totalDelta)))
  }
}

struct GPURawResidency {
  /// Nanoseconds the GPU has spent in any non-idle state.
  let active: Int64
  /// Nanoseconds the GPU has spent across all states (idle + active).
  let total: Int64
}

protocol IOReportBridgeProtocol {
  func readGPUResidency() -> GPURawResidency
}

/// Thin wrapper around the private IOReport framework, opened via dlopen.
/// On Apple Silicon, the GPU performance-state channel is in the "GPU Stats"
/// channel group of the IOReport `Energy Model` subsystem.
final class IOReportBridge: IOReportBridgeProtocol {
  private typealias IOReportCopyChannelsInGroup_t = @convention(c) (
    CFString?, CFString?, UInt64, UInt64, UInt64
  ) -> Unmanaged<CFMutableDictionary>?
  private typealias IOReportCreateSubscription_t = @convention(c) (
    UnsafeRawPointer?, CFMutableDictionary, UnsafeMutablePointer<Unmanaged<CFMutableDictionary>?>, UInt64, CFTypeRef?
  ) -> Unmanaged<AnyObject>?
  private typealias IOReportCreateSamples_t = @convention(c) (
    AnyObject, CFMutableDictionary, CFTypeRef?
  ) -> Unmanaged<CFDictionary>?
  private typealias IOReportCreateSamplesDelta_t = @convention(c) (
    CFDictionary, CFDictionary, CFTypeRef?
  ) -> Unmanaged<CFDictionary>?

  private let handle: UnsafeMutableRawPointer
  private let copyChannels: IOReportCopyChannelsInGroup_t
  private let createSubscription: IOReportCreateSubscription_t
  private let createSamples: IOReportCreateSamples_t
  private let createDelta: IOReportCreateSamplesDelta_t

  private let subscription: AnyObject
  private let channels: CFMutableDictionary
  private var lastSample: CFDictionary?

  init?() {
    guard let h = dlopen("/usr/lib/libIOReport.dylib", RTLD_LAZY) else { return nil }
    handle = h

    func sym<T>(_ name: String, _ type: T.Type) -> T? {
      guard let p = dlsym(h, name) else { return nil }
      return unsafeBitCast(p, to: type)
    }

    guard
      let cc = sym("IOReportCopyChannelsInGroup", IOReportCopyChannelsInGroup_t.self),
      let cs = sym("IOReportCreateSubscription", IOReportCreateSubscription_t.self),
      let csa = sym("IOReportCreateSamples", IOReportCreateSamples_t.self),
      let cd = sym("IOReportCreateSamplesDelta", IOReportCreateSamplesDelta_t.self)
    else {
      dlclose(h)
      return nil
    }
    copyChannels = cc
    createSubscription = cs
    createSamples = csa
    createDelta = cd

    guard let chans = copyChannels("GPU Stats" as CFString, nil, 0, 0, 0)?.takeRetainedValue() else {
      dlclose(h)
      return nil
    }
    channels = chans

    var sub: Unmanaged<CFMutableDictionary>? = nil
    guard let s = createSubscription(nil, chans, &sub, 0, nil)?.takeRetainedValue() else {
      dlclose(h)
      return nil
    }
    subscription = s
  }

  deinit {
    dlclose(handle)
  }

  func readGPUResidency() -> GPURawResidency {
    guard let sample = createSamples(subscription, channels, nil)?.takeRetainedValue() else {
      return GPURawResidency(active: 0, total: 0)
    }

    let target: CFDictionary
    if let prev = lastSample, let delta = createDelta(prev, sample, nil)?.takeRetainedValue() {
      target = delta
    } else {
      target = sample
    }
    lastSample = sample

    return Self.parseGPUResidency(from: target)
  }

  static func parseGPUResidency(from dict: CFDictionary) -> GPURawResidency {
    let ns = (dict as NSDictionary)
    guard let items = ns["IOReportChannels"] as? [[String: Any]] else {
      return GPURawResidency(active: 0, total: 0)
    }
    var active: Int64 = 0
    var total: Int64 = 0
    for item in items {
      guard let group = item["IOReportChannelGroup"] as? String,
            let name = item["IOReportChannelName"] as? String,
            group == "GPU Stats",
            let raw = item["IOReportChannelValue"] as? Int64 else { continue }
      total &+= raw
      if name != "GPU Idle Residency" {
        active &+= raw
      }
    }
    return GPURawResidency(active: active, total: total)
  }
}
