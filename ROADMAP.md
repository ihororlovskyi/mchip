# Roadmap

Forward-looking work for ChipBar. Items move from here to `CHANGELOG.md`
once shipped on a tagged release.

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
- Add `quarantine: false` to `Casks/chipbar.rb` in
  [`ihororlovskyi/homebrew-tap`](https://github.com/ihororlovskyi/homebrew-tap)
  so future `brew install --cask chipbar` runs no longer trigger
  Gatekeeper's "needs to be updated" prompt on ad-hoc-signed builds.

## Known issues

_None tracked at the moment._

## Out of scope (v0.1.x)

These are intentional non-goals for the current minor series. They can be
revisited in a later major bump if the scope changes.

- Notarization / Developer ID signing — releases are ad-hoc signed only.
- Universal binary — `arm64` only; Intel is not supported.
- Localization — UI is English-only by design.
