# ChipBar

A tiny macOS monitor for Apple Silicon chips.

Design
```md
  CPU  GPU  RAM
  20%   4%  20%
```

How it works

ChipBar lives in the macOS menu bar as a single, compact item with three
fixed-width cells: `CPU`, `GPU`, and `RAM`. Each cell shows the current
utilisation as an integer percentage rounded to `%`. The bar repaints itself
on every sample tick so the readings stay live without animation.

Samples come from a `MetricsSampler` actor that ticks on a fixed interval
(1 s or 2 s, picked in the dropdown) and pulls one value from each reader:

- `CPUReader` — delta of Mach `host_cpu_load_info` between ticks; the first
  tick returns `0%` because there is no previous baseline.
- `GPUReader` — enumerates `IOAccelerator` services in the public IOKit
  registry and reads `Device Utilization %` from each one's
  `PerformanceStatistics` dictionary, taking the highest value across
  services. Works for Apple Silicon (AGX) and Intel + AMD/NVIDIA discrete
  GPUs alike.
- `RAMReader` — `host_statistics64` on the wired + active + compressed pages
  divided by the total page count.

All values are clamped to `[0, 1]` before they reach the view, so an
overshooting sampler can never render `> 100%`.

Dropdown menu

Clicking the bar opens a menu with:

- Three rows — `CPU`, `GPU`, `RAM` — showing the latest percentages. Each
  row also acts as a checkbox: toggling it hides or shows that metric in the
  menu-bar item. The status bar shrinks or grows so unused cells leave no
  empty space, and the last visible metric cannot be turned off.
- `Update every` submenu with `1 second` / `2 seconds` (checked = active).
  The selection persists across launches via `UserDefaults`
  (`chipbar.refreshIntervalSeconds`).
- `About` submenu showing the app name, version (`v<MARKETING_VERSION>`),
  build date (mtime of the bundled executable, formatted `dd MMM yy`), and
  a `GitHub` entry that opens the project repository in the default browser.
- `Quit mchip` — clean shutdown of the sampler and the AppKit run loop.

Visibility flags are persisted as `chipbar.show.cpu`, `chipbar.show.gpu`,
`chipbar.show.ram`. If all three are saved as `false` (e.g. by manual
defaults editing), the app falls back to showing all three on next launch.

Runtime constraints

- macOS 14+, Apple Silicon only (`arm64`). No Dock icon
  (`LSUIElement = true`), no main window, no login item.
- AppKit on the main actor; metric reads are off-main but funnelled through
  an `AsyncStream<Snapshot>` so the UI never observes a partial sample.

Install
```zsh
brew tap ihororlovskyi/tap
brew install chipbar
```

See [CHANGELOG.md](CHANGELOG.md) for release notes and [ROADMAP.md](ROADMAP.md) for upcoming work.

Have fun ;)
