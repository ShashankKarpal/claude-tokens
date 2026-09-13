#!/bin/bash
# ccusage-today: today's Claude Code usage as one line of JSON.
#
# This is the single extractor behind the claude-tokens desktop widget and
# any menu bar tile that shows the same number. The widget must stay a
# self-contained file for gallery users, so it carries a verbatim copy of the
# body below; CI (verify-widget-zip.yml) and tests/selftest.sh diff the two
# and fail on any drift. Edit here, then paste the same lines into
# claude-tokens.widget/index.coffee under `command: """`.
#
# Output contract (one JSON object, always exit 0):
#   {"status":"ok","date":"YYYY-MM-DD","input":N,"output":N,
#    "cacheRead":N,"cacheWrite":N,"total":N,"cost":F}
#   {"status":"empty","date":"YYYY-MM-DD"}
#   {"status":"error","message":"ccusage not available"}
#
# Cache: consumers polling every 30 s share one ccusage call through a small
# file in the per-user temp dir (override with CLAUDE_TOKENS_CACHE_DIR), keyed
# by day so a new day never reads yesterday's file, written by atomic rename,
# owner-only, 20 s of freshness. Errors are never cached.
#
# --- widget command (kept identical to claude-tokens.widget/index.coffee) ---
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
TODAY=$(date +%Y-%m-%d)
SINCE=$(date -v-1d +%Y%m%d 2>/dev/null || date -d yesterday +%Y%m%d)
DIR="${CLAUDE_TOKENS_CACHE_DIR:-$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || echo "${TMPDIR:-/tmp}")}"
CACHE="$DIR/claude-tokens-today-$TODAY.json"
if [ -s "$CACHE" ]; then
  AGE=$(( $(date +%s) - $(stat -f %m "$CACHE" 2>/dev/null || stat -c %Y "$CACHE") ))
  [ "$AGE" -lt 20 ] && { cat "$CACHE"; exit 0; }
fi
# One ccusage call bounded to two days (not the whole history every 30s) and
# one jq pass that builds the JSON itself, so a null or string field can
# never produce a malformed payload. Accepts .date or .period as the day key.
# `ccusage claude daily`, not `ccusage daily`: since ccusage counts every
# coding agent it detects, the bare command sums Claude Code with Codex and
# others, and this tile says Claude Code. The claude subcommand is the
# Claude-only readout. --offline prices from ccusage's bundled table instead
# of fetching one over the network on every tick: measured 6 to 9 s of
# socket wait versus 0.1 s, byte-identical figures. Token counts never
# depend on it; the cost line catches up when ccusage is upgraded.
OUT=$(ccusage claude daily --json --since "$SINCE" --offline 2>/dev/null | jq -c --arg t "$TODAY" '
  ((.daily // []) | map(select((.date // .period) == $t)) | .[0]) as $d
  | if $d == null then {status:"empty", date:$t}
    else {status:"ok", date:$t,
          input:($d.inputTokens // 0), output:($d.outputTokens // 0),
          cacheRead:($d.cacheReadTokens // 0), cacheWrite:($d.cacheCreationTokens // 0),
          total:($d.totalTokens // 0), cost:($d.totalCost // 0)} end' 2>/dev/null)
if [ -n "$OUT" ]; then
  (umask 077; echo "$OUT" > "$CACHE.$$" && mv -f "$CACHE.$$" "$CACHE") 2>/dev/null
  find "$DIR" -maxdepth 1 '(' -name 'claude-tokens-today-*.json' ! -name "claude-tokens-today-$TODAY.json" -o -name 'claude-tokens-today-*.json.*' -mmin +5 ')' -delete 2>/dev/null
  echo "$OUT"
else
  echo '{"status":"error","message":"ccusage not available"}'
fi
