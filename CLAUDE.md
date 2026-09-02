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
