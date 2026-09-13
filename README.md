<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)"  srcset="design/github/readme-banner-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="design/github/readme-banner-light.svg">
    <img alt="Claude Code Tokens" src="design/github/readme-banner-dark.svg" width="680">
  </picture>
</p>

<h1 align="center">claude-tokens</h1>

<p align="center"><b>An Ubersicht widget showing daily Claude Code token usage as a desktop tile on macOS.</b></p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS-2D647F?style=flat-square">
  <img alt="Status" src="https://img.shields.io/badge/status-v1.1-2D647F?style=flat-square">
  <img alt="No API keys" src="https://img.shields.io/badge/API%20keys-none-2D647F?style=flat-square">
  <img alt="Stack" src="https://img.shields.io/badge/built%20with-CoffeeScript-1A1917?style=flat-square">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-1A1917?style=flat-square"></a>
</p>

## What it does

- Shows today's Claude Code token total on the desktop, formatted with k and M suffixes. Claude Code only: ccusage also detects other coding agents (Codex CLI and friends), and those are deliberately left out of this tile.
- Counts every Claude Code CLI session run under your macOS user, whichever Claude account was signed in at the time (they all write to the same local log folder). The Claude desktop app and claude.ai are not part of the number.
- Breaks the total into input, output, cache create, and cache read.
- Shows the API-pricing equivalent of that usage, and optionally what share of one day of your subscription that is (see the plan ROI row below).
- Refreshes every 30 seconds. No network call: ccusage runs in offline mode and prices from its bundled table.

## Features

- **Desktop tile.** Renders through Ubersicht, always visible, never in the way.
- **Full token breakdown.** Input, output, cache create, cache read, and total.
- **Cost equivalent.** ccusage's API-pricing figure for the same usage.
- **Last update time** shown under the total.
- **Plan ROI row (optional).** One number in a config file turns on a row showing today's cost as a share of one day of your plan.
- **Shared data source.** The extractor script behind the tile can feed a menu bar app or any other script, and consumers share one cached ccusage call.
- **Configurable display.** Pin to a specific monitor by replacing `display: 'main'` with the function form.
- **Configurable position.** Edit `bottom:` and `left:` in the `style:` block.
- **Configurable refresh.** 30 seconds by default.
- **No credentials, no network.** ccusage reads Claude Code's local JSONL logs and runs with `--offline`, so nothing leaves the machine and the tick never waits on a fetch. The cost line uses the pricing table bundled with your ccusage version; upgrade ccusage to pick up new models.

## Stack

- Widget: CoffeeScript, rendered by [Ubersicht](http://tracesof.net/uebersicht/)
- Usage data: [ccusage](https://github.com/ryoppippi/ccusage)
- JSON handling: jq

## Install

Requires: Ubersicht, ccusage (a version with the `ccusage claude` subcommand; tested with 20.1.0), jq.

```bash
brew install ccusage jq
git clone https://github.com/ShashankKarpal/claude-tokens.git
cp -r claude-tokens/claude-tokens.widget ~/Library/Application\ Support/Übersicht/widgets/
```

Click the Ubersicht menu bar icon and choose Refresh all. Upgrading from an earlier copy: replace the folder the same way; there is nothing else to migrate.

## Usage

![Widget](design/github/screenshot.png)

The tile appears on the desktop and updates itself. No interaction needed. If ccusage is missing the tile says so instead of showing a number; a day with no Claude Code use reads 0.

## Project structure

```
claude-tokens.widget/     the widget (index.coffee)
claude-tokens.widget.zip  packaged widget for the Ubersicht gallery
bin/ccusage-today.sh      the extractor, one JSON line; the widget embeds the same body
tests/selftest.sh         parity, output states, cache (bash tests/selftest.sh)
widget.json               gallery manifest
design/                   brand assets, tokens, BRAND.md
```

## Using the same number elsewhere

`bin/ccusage-today.sh` prints today's figures as one JSON object (`status` is `ok`, `empty`, or `error`). A menu bar tile or any other script can call it instead of running ccusage again: consumers polling every 30 seconds share one ccusage call through a small per-user cache file (20 seconds of freshness, keyed by day, owner-only, never caches an error). The widget stays a single self-contained file, so it carries a verbatim copy of the script body; CI and the selftest diff the two and fail on drift. Set `CLAUDE_TOKENS_CACHE_DIR` to move the cache.

## Optional: plan ROI line

Put the monthly price of your Claude subscription, as one number, in `~/.config/claude-tokens/plan-usd-month` (for example `200`). The tile then adds a row such as `Plan ROI  18.5% of $6.67/day`: today's API-equivalent cost as a share of what one day of the plan costs (30-day month). No file, a zero, or anything that is not a number means the row is simply absent. The file lives outside the repo and is read on every refresh, so a change shows within about 20 seconds.

## Note on cost

The cost figure is ccusage's API-pricing equivalent of your usage. It is not a bill. Claude Code subscriptions cover this usage; the number is for awareness.

## Development

The widget's `command:` block is a verbatim copy of `bin/ccusage-today.sh` from its marker line down. To change how the number is computed: edit the script, paste the same lines into `claude-tokens.widget/index.coffee`, run `bash tests/selftest.sh` (fake ccusage, isolated cache, no real data touched), rebuild the gallery zip with `COPYFILE_DISABLE=1 zip -r -X claude-tokens.widget.zip claude-tokens.widget`, and copy `index.coffee` over your installed widget. CI repeats the zip check, the parity diff and the selftest on every push, and only then updates the `master` publish pointer. Two things the selftest guards that are easy to miss: the command block must not contain a backslash (CoffeeScript consumes it before the shell sees it), and it must parse under plain `sh`.

## Note on branches

`main` is the development branch. `master` is a publish pointer that CI force-updates to `main` after the zip check passes, because the Ubersicht gallery links this widget's screenshot and zip at `master` URLs. Nothing is ever committed to `master` directly; do not delete it.

## Compatibility

Apple Silicon, macOS 14 or later. Works on any Mac that runs Ubersicht.

## License

MIT. See [LICENSE](LICENSE).

## Author

Built by Shashank Karpal.

> Built with Claude (Anthropic) as a debugging partner. Design, decisions, and final review were the author's.
