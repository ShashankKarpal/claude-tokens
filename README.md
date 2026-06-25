# uebersicht-claude-tokens

An [Übersicht](http://tracesof.net/uebersicht/) widget that shows daily Claude Code token usage as a desktop tile on macOS.

![Widget screenshot](docs/claude-tokens.png)

## What it shows

- Today's total tokens, formatted with k or M suffixes
- Input, Output, Cache create, Cache read breakdown
- Approximate API-equivalent cost from ccusage
- Last update time

## Requires

- [Übersicht](http://tracesof.net/uebersicht/)
- [ccusage](https://github.com/ryoppippi/ccusage) for parsing Claude Code's local JSONL logs
- `jq` for JSON manipulation

Install ccusage and jq via Homebrew:

```bash
brew install ccusage jq
```

ccusage reads `~/.claude/projects/` locally. No network calls, no API keys.

## Install

```bash
cp -r claude-tokens.widget ~/Library/Application\ Support/Übersicht/widgets/
```

Click the Übersicht menu bar icon and choose Refresh all.

## Configure

- **Display**: `display: 'main'` by default. To pin to a specific monitor, replace with a function form (see Übersicht docs).
- **Position**: edit `bottom:` and `left:` in the `style:` block.
- **Refresh interval**: 30 seconds by default.

## Note on cost

The cost figure is ccusage's API-pricing equivalent of your usage. It is not a bill. Claude Code subscriptions cover this usage; the number is for awareness, not payment.

## Compatibility

Built and tested on macOS Tahoe, MacBook Pro M4 Pro. Works on any Mac that runs Übersicht.

## License

MIT. See [LICENSE](LICENSE).

## Notes

Developed with Claude (Anthropic) as a debugging partner. Design, decisions, and final review were mine.
