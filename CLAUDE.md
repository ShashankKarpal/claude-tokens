# CLAUDE.md

## Security and hygiene rules (every agent session)

1. Never commit secrets: no API keys, tokens, passwords, private keys, or .env files. Templates belong in *.example files with placeholder values only.
2. Untracking or deleting a file does not remove it from git history. If a secret ever lands in a commit: rotate it at the provider first, then rewrite history with git filter-repo.
3. At the end of each session: delete unused code, merge duplicate helpers, remove commented-out blocks. Use deterministic tools (linters, dead-code finders) and review the diff before deleting.
4. Keep .gitignore covering .env, .env.*, and secrets.* (with !*.example exemptions). Never weaken it.
5. The gitleaks CI workflow (.github/workflows/gitleaks.yml) stays. Never remove or bypass it.

## 2026-09-02: fleet audit pass (kk1)
- The gallery zip was stale: it still carried the pre-refresh icon colours (#2FD4C4/#F7F5F2) two weeks after the 2026-08-24 brand refresh, because CI only checked that the path existed inside the zip. CI now diffs the zip payload against the source byte for byte and fails on AppleDouble entries; the zip was rebuilt with `COPYFILE_DISABLE=1 zip -r -X`.
- Widget command collapsed to one bounded ccusage call (`--since` yesterday) and one jq pass that builds the JSON, so a null field can no longer break the payload and the 30s tick stops scanning the whole history. Day-key selector `(.date // .period)` is now also used by the menu bar host's copy of this readout, so the two never disagree.
- docs/STATE.md remote name corrected to claude-tokens.
- Deferred to the fleet roadmap: a "today as share of the derived weekly budget" row once the statusline suite ships its sample history.

## 2026-09-13: Claude-only scope, offline pricing, shared extractor (kk2)
- BUG FIXED: `ccusage daily` (20.x) sums every coding agent it detects (`agent: "all"`), so on days Codex CLI ran the tile over-reported by up to three orders of magnitude (2026-09-03: 28.97M shown, 42.4k actual). Read `ccusage claude daily` (day key `.date`; keep the `(.date // .period)` selector). RULE: never the bare `daily` in this repo.
- `--offline` on the ccusage call: the bare call fetched a pricing table on every 30 s tick (2 to 9 s of wait); figures are byte-identical from the bundled table. README's "no network" claim depends on this flag staying.
- `bin/ccusage-today.sh` is the single extractor (one JSON line, status ok|empty|error, optional plan fields). The widget's `command:` block is a VERBATIM copy of the script after the `# --- widget command` marker; CI (`verify-widget-zip.yml`) diffs the two and runs `tests/selftest.sh` (23 checks) on Ubuntu, so keep both copies in step and keep the body free of backslashes (CoffeeScript eats them) and bash-only syntax (it must parse under `sh`).
- Shared cache: per-user temp dir via `getconf DARWIN_USER_TEMP_DIR` (fallback `$TMPDIR`, then `/tmp`; override `CLAUDE_TOKENS_CACHE_DIR`), file `claude-tokens-today-<date>.json`, 20 s TTL, atomic rename, 0600, errors never cached. Portability: GNU `stat -c` first, BSD `stat -f` second (GNU `stat -f` succeeds with the wrong answer).
- Plan ROI row: `~/.config/claude-tokens/plan-usd-month` (override dir `CLAUDE_TOKENS_CONFIG_DIR`), one number; absent, zero or malformed means no plan fields. Runtime config, never in the repo.
- Release path for any extractor change: edit script, paste into the widget, `bash tests/selftest.sh`, rebuild the zip with `COPYFILE_DISABLE=1 zip -r -X claude-tokens.widget.zip claude-tokens.widget`, copy `index.coffee` into the installed widget folder and `cmp` it, commit, push; CI then moves `master`.
- `docs/STATE.md` is excluded through `.git/info/exclude` (local-only); `CHANGELOG.md` is the tracked history. Screenshots (`screenshot.png`, `design/github/screenshot.png`, `docs/claude-tokens.png`) date from 2026-07-07 and predate the brand refresh and today's rows; owner retakes them.
