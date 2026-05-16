# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_No unreleased changes._

See [ROADMAP.md](ROADMAP.md) for planned work and explicit non-goals.

## [0.1.1] — 2026-05-16

### Added

- Per-metric visibility toggles: `CPU` / `GPU` / `RAM` rows in the dropdown now act as checkboxes that hide or show the corresponding cell in the menu-bar item. Persisted as `chipbar.show.cpu` / `chipbar.show.gpu` / `chipbar.show.ram`. The last visible metric cannot be turned off; if all three are stored as `false`, the app falls back to showing all on next launch.
- `About` submenu in the dropdown, listing the app name (`mchip`), version (`v<CFBundleShortVersionString>`), build date (executable `mtime`, formatted `dd MMM yy`), and a `GitHub` entry that opens the repository (`https://github.com/ihororlovskyi/chipbar`) in the default browser.

### Changed

- User-facing app name is now `mchip` (`CFBundleDisplayName`); menu quit item reads `Quit mchip`. Bundle identifier, scheme, target name, scripts, cask, and `UserDefaults` keys remain `chipbar`/`Chipbar` — no migration needed.
- Status-bar item width is now derived from the number of visible metrics instead of a fixed three-cell width.
- `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` bumped to `0.1.1`.
- `GPUReader` rewritten on top of public IOKit: enumerates `IOAccelerator` services and reads `Device Utilization %` from each one's `PerformanceStatistics` dictionary, taking the maximum across services. The private `libIOReport.dylib` `dlopen` bridge (`IOReportBridge`, `IOReportCopyChannelsInGroup` / `IOReportCreateSubscription` / `IOReportCreateSamples` / `IOReportCreateSamplesDelta`, `GPU Stats` channel filtering, `GPU Idle Residency` parsing, delta-based residency math, `primed`/`previousActive`/`previousTotal` state) is gone. Works on Apple Silicon (AGX) and Intel + AMD/NVIDIA discrete GPUs alike.

### Fixed

- GPU usage rendering on Apple Silicon: previously always reported `0%` under load. The new `IOAccelerator` / `Device Utilization %` path returns live utilisation.

## [0.1.0] — 2026-05-16

Initial release.

### Added

- macOS menu bar app showing CPU / GPU / RAM utilisation, refreshed every 1s or 2s.
- `CPUReader` using `host_cpu_load_info`.
- `GPUReader` using the private IOReport framework (`/usr/lib/libIOReport.dylib`), with fault-tolerant fallback to a zero reader when the API is unavailable (e.g. headless CI runners).
- `RAMReader` using `host_statistics64`.
- `MetricsSampler` actor with reschedulable interval.
- `Preferences` wrapper over UserDefaults with a publisher for refresh-interval changes.
- `StatusBarController` + `StatusBarView` two-row icon + percentage rendering with a click-through menu (interval picker + Quit).
- XcodeGen `project.yml` (arm64, manual ad-hoc signing).
- `xcodebuild` test suite (17 tests covering CPU, GPU, RAM, Sampler, Preferences, Snapshot).
- GitHub Actions: `ci` (tests on PR / push to main, `macos-15` runner) and `release` (tag-triggered build, sign, zip, GitHub release, Homebrew cask bump).
- `scripts/build-release.sh` — archive, export, ad-hoc sign, zip; stamps `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` into `Info.plist`.
- `scripts/update-cask.sh` — bumps `version` / `sha256` in the tap cask.
- Homebrew tap at [`ihororlovskyi/homebrew-tap`](https://github.com/ihororlovskyi/homebrew-tap), installable via `brew install --cask chipbar`.

[Unreleased]: https://github.com/ihororlovskyi/chipbar/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/ihororlovskyi/chipbar/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/ihororlovskyi/chipbar/releases/tag/v0.1.0
