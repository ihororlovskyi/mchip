# Roadmap

Forward-looking work for ChipBar. Items move from here to `CHANGELOG.md`
once shipped on a tagged release.

## Next patch (v0.1.3)

- **App icon.** Ship a real `.icns` in the bundle so Finder / Dock / Cmd-Tab /
  Launchpad / "Open With" all show the mchip artwork instead of the generic
  placeholder app icon. Wire it via `CFBundleIconFile` /
  `CFBundleIconName` in `Sources/Chipbar/App/Info.plist` and an
  `AppIcon.appiconset` (or single `.icns`) added to the Chipbar target in
  `project.yml`. (The menu-bar item stays text-only — that is by design.)
- **README screencast / GIF.** Record a short loop of the menu-bar item +
  dropdown (visibility toggles, `Update every`, `About`) and embed it at
  the top of `README.md`. Source recording with `Cmd-Shift-5` (selection +
  10–15 s), convert `.mov` → `.gif` with `ffmpeg` (≤ ~2 MB, ~12 fps).
  Store under `docs/` or `assets/` so the binary doesn't pollute source
  diffs.
- **Drop the `Chipbar` name entirely.** Today the user-facing artifact is
  `mchip-v<version>.app` but the Xcode target, scheme, executable inside the
  bundle (`Contents/MacOS/Chipbar`), `Chipbar.xcodeproj`, archive path
  (`build/Chipbar.xcarchive`), release zip prefix (`Chipbar-<version>.zip`),
  and a handful of CI / script references still say `Chipbar`. Rename them
  to `mchip` so no internal trace of the old name remains. Touches
  `project.yml` (target + scheme), `Sources/Chipbar/` directory layout,
  `Chipbar.xcodeproj` (regenerate via `xcodegen generate`),
  `scripts/build-release.sh` (`ARCHIVE`, `APP`, `ZIP` paths),
  `scripts/update-cask.sh` invocation, `.github/workflows/release.yml`
  (test/build/release artifact names), in-tree agent docs, `README.md`,
  and the Homebrew cask `url` stanza (release zip filename changes from
  `Chipbar-<v>.zip` to `mchip-<v>.zip`).
  Keep `CFBundleIdentifier = com.ihororlovskyi.chipbar` to preserve
  LaunchServices identity and granted permissions; the rename is
  cosmetic / structural only. UserDefaults keys (`chipbar.show.*`,
  `chipbar.refreshIntervalSeconds`) also stay so v0.1.2 users keep their
  settings.
- **Snapshot tests for `StatusBarView`.** Add deterministic rendering
  tests that draw the custom `NSView` offscreen (1-, 2-, 3-cell layouts ×
  representative percentage values) into `NSImage`/`CGImage`, diff against
  reference PNGs under `Tests/ChipbarTests/__Snapshots__/`, and fail on
  pixel-level drift. Either pull in `pointfreeco/swift-snapshot-testing`
  via SwiftPM or roll a 50-line in-tree helper using `NSGraphicsContext` +
  `CGImage` byte compare. Replaces the visual-only part of the manual
  smoke checklist (bar rendering with 1/2/3 visible cells and metric
  toggling). Manual checklist keeps the items that touch `NSStatusItem`,
  `About`, `Update every`, and live CPU/GPU load.
- **Refresh-interval menu polish.** Rename the parent menu item
  `Update every` → a single word (`Interval`). Shorten the leaf labels
  `1 second` / `2 seconds` → `1 sec` / `2 sec`, and add new options
  `0.5 sec` and `5 sec`. Default stays `1 sec`. Touches
  `Preferences.allowedIntervals` (expand from `[1, 2]` to
  `[0.5, 1, 2, 5]` and switch the stored type from `Int` to `Double` —
  bump the UserDefaults key to `chipbar.refreshIntervalSecondsV2` and
  migrate the old `chipbar.refreshIntervalSeconds` value on first read so
  v0.1.2 users keep their choice), `MetricsSampler` (already accepts a
  `TimeInterval`, just make sure sub-second cadence doesn't starve the
  main actor), and `StatusBarController.buildMenu` (four leaf items +
  rename submenu title). Update `PreferencesTests` for the new allow-list
  + migration path, and extend the manual smoke checklist to cover the
  four cadences.
- **About-menu layout.** Collapse the current three info rows into a
  single inline row `mchip • v<version> • <dd MMM yy>` (e.g.
  `mchip • v0.1.2 • 18 May 26`), and add a second non-clickable row
  beneath it with the English call-to-action `Leave feedback on GitHub
  issues` (or similar wording — finalise during implementation). The
  existing clickable `GitHub` row keeps its current behaviour (opens
  `https://github.com/ihororlovskyi/mchip`). Touches
  `StatusBarController.makeAboutSubmenu` and the About row in the manual
  smoke checklist.

## Planned

- Launch at login.
- Additional metrics: disk, network, temperature, energy.
- Refresh intervals beyond `1 s` / `2 s` (e.g. `500 ms`, `5 s`).
- Lightweight graphs / short-term history per metric.
- Threshold alerts (notification when a metric crosses a configurable
  ceiling, e.g. CPU > 90% for N seconds).
- Single-row menu-bar layout (`CPU 19%  GPU 49%  MEM 72%`) replacing the
  current two-row label + value cells, per the design example in
  `README.md`.

## Known issues

_None tracked at the moment._

## Future (v0.2.x+)

- **Apple verification (Developer ID + notarization).** Sign releases with a
  real `Developer ID Application` certificate instead of ad-hoc, enable
  hardened runtime (`--options=runtime`), submit the artifact to Apple via
  `xcrun notarytool submit --wait`, then `xcrun stapler staple` it before
  zipping for release. Removes the Gatekeeper "could not verify" dialog on
  first launch for every user (not just brew-cask users), and removes the
  need for `quarantine: false` workarounds. Requires:
  - Apple Developer Program membership (paid, ~$99/year).
  - `Developer ID Application` certificate exported to the CI keychain.
  - Apple ID + app-specific password (or notarytool API key) stored as
    GitHub Actions secrets.
  - `scripts/build-release.sh` updated to use the real identity, and a new
    notarize + staple step before `ditto`.
  - `release.yml` updated to import the certificate, run notarization, and
    keep the existing tap-bump step (the cask can drop `quarantine: false`
    once notarization is in place).

## Out of scope (v0.1.x)

These are intentional non-goals for the current minor series. They can be
revisited in a later major bump if the scope changes.

- Universal binary — `arm64` only; Intel is not supported.
- Localization — UI is English-only by design.
