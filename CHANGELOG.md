# Changelog

All notable changes to the claude-tokens widget. Dates are the day the change
landed on `main`; `master` follows automatically (publish pointer, see README).

## 2026-09-13

- Optional plan ROI row: `~/.config/claude-tokens/plan-usd-month` (one
  number, outside the repo) adds "Plan ROI: N% of $X/day" to the tile; absent,
  zero or malformed means no row. Computed in the shared extractor, so any
  consumer of it gets the same fields.
- Shared extractor `bin/ccusage-today.sh`: one JSON line (`status` ok, empty
  or error) that other tiles can render instead of running ccusage again;
  consumers polling every 30 s share one ccusage call through a per-user cache
  (20 s, keyed by day, owner-only, atomic, errors never cached). The widget
  embeds the same body; CI and `tests/selftest.sh` (18 checks) fail on drift.
- Offline pricing: `--offline` on the ccusage call. The bare call fetched a
  pricing table over the network on every tick (2 to 9 s of wait for 0.13 s of
  CPU); figures are byte-identical from the bundled table and the tick takes
  0.1 s. README's "no network" sentence is true again.
- Fix: Claude-only scope. ccusage 20.x `daily` sums every coding agent it
  detects (`agent: "all"`), so on days Codex CLI ran the tile over-reported
  by up to three orders of magnitude (2026-09-03: 28.97M shown, 42.4k
  actual). The widget now reads `ccusage claude daily`.
- README: scope, network and branch notes; this changelog created.

## 2026-09-02

- One bounded ccusage call (`--since` yesterday) and one jq pass that builds
  the payload, so a null field cannot break it; day key accepts `.date` or
  `.period`.
- CI diffs the gallery zip payload against the source byte for byte and
  fails on AppleDouble entries; the zip had shipped stale icon colours for two
  weeks.

## 2026-08-24

- Ink and Bone brand refresh: icon colours, README banners, provenance files.

## 2026-08-18

- Repository renamed from uebersicht-claude-tokens to claude-tokens.

## 2026-08-05

- CI `sync-master` job force-updates `master` to `main` after the zip check,
  because the Ubersicht gallery links this widget at `master` URLs.

## 2026-08-01

- v1.0 accepted into the Ubersicht widget gallery (issue #710). Zip layout
  fixed to wrap the `.widget` folder; CI check added.
