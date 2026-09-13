#!/bin/bash
# Selftest for the claude-tokens extractor: parity between bin/ccusage-today.sh
# and the widget's inline command, the three output states, and the shared
# cache. Uses a fake ccusage (exported shell function) and a private cache
# dir, so it never touches the live cache or needs ccusage installed.
# Run: bash tests/selftest.sh    (exit 0 = all OK; CI runs it on every push)
set -u
cd "$(dirname "$0")/.." || exit 2
SCRIPT=bin/ccusage-today.sh
WIDGET=claude-tokens.widget/index.coffee
FAILS=0; N=0
ok(){ N=$((N+1)); echo "ok   $N $1"; }
bad(){ N=$((N+1)); FAILS=$((FAILS+1)); echo "FAIL $N $1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }

T=$(mktemp -d "${TMPDIR:-/tmp}/ct-selftest.XXXXXX")
trap 'rm -rf "$T"' EXIT
export CLAUDE_TOKENS_CACHE_DIR="$T/cache"; mkdir -p "$CLAUDE_TOKENS_CACHE_DIR"
export CLAUDE_TOKENS_CONFIG_DIR="$T/config"; mkdir -p "$CLAUDE_TOKENS_CONFIG_DIR"   # never the owner's real file
COUNT="$T/calls"; : > "$COUNT"; export COUNT
TODAY=$(date +%Y-%m-%d); export TODAY

CMD=$(awk '/^command: """/{f=1;next} f&&/^"""/{exit} f' "$WIDGET" | sed 's/^  //')
BODY=$(sed -n '/^# --- widget command/,$p' "$SCRIPT" | tail -n +2)

# 1. parity and syntax
check "widget command block equals the script body after the marker" '[ "$CMD" = "$BODY" ]'
check "script parses (bash -n)" 'bash -n "$SCRIPT"'
check "widget command parses under sh (POSIX)" 'printf "%s\n" "$CMD" | sh -n'
check "widget command carries no backslash (CoffeeScript would eat it)" '! printf "%s" "$CMD" | grep -q "\\\\"'
check "script is executable in git (mode 100755)" '[ "$(git ls-files -s "$SCRIPT" 2>/dev/null | cut -c1-6)" = "100755" ] || [ ! -d .git ]'

run_script(){ bash "$SCRIPT" 2>/dev/null; }
run_widget(){ bash -c "$CMD" 2>/dev/null; }
clear_cache(){ rm -f "$CLAUDE_TOKENS_CACHE_DIR"/claude-tokens-today-*; : > "$COUNT"; }
calls(){ wc -l < "$COUNT" | tr -d ' '; }

# 2. ok state
ccusage(){ echo "$*" >> "$COUNT"; printf '{"daily":[{"date":"%s","inputTokens":1200,"outputTokens":340,"cacheCreationTokens":5000,"cacheReadTokens":88000,"totalTokens":94540,"totalCost":1.2345}],"totals":{}}\n' "$TODAY"; }
export -f ccusage
clear_cache; A=$(run_script)
check "ok payload" '[ "$A" = "{\"status\":\"ok\",\"date\":\"$TODAY\",\"input\":1200,\"output\":340,\"cacheRead\":88000,\"cacheWrite\":5000,\"total\":94540,\"cost\":1.2345}" ]'
check "ccusage argv is: claude daily --json --since <d> --offline" 'grep -qE "^claude daily --json --since [0-9]{8} --offline$" "$COUNT"'
clear_cache; B=$(run_widget)
check "widget command gives the same payload" '[ "$A" = "$B" ]'
check "cache file written for today" '[ -s "$CLAUDE_TOKENS_CACHE_DIR/claude-tokens-today-$TODAY.json" ]'
MODE=$(stat -f %Lp "$CLAUDE_TOKENS_CACHE_DIR/claude-tokens-today-$TODAY.json" 2>/dev/null || stat -c %a "$CLAUDE_TOKENS_CACHE_DIR/claude-tokens-today-$TODAY.json")
check "cache file is owner-only (600)" '[ "$MODE" = "600" ]'

# 3. cache hit within 20 s: two consumers, one ccusage call
clear_cache; run_script >/dev/null; C=$(run_widget)
check "second consumer within TTL served from cache (1 call total)" '[ "$(calls)" = "1" ] && [ "$C" = "$A" ]'
# 4. cache expiry
OLD=$(( $(date +%s) - 30 ))
touch -t "$(date -r "$OLD" +%Y%m%d%H%M.%S 2>/dev/null || date -d "@$OLD" +%Y%m%d%H%M.%S)" "$CLAUDE_TOKENS_CACHE_DIR/claude-tokens-today-$TODAY.json"
run_script >/dev/null
check "cache older than 20 s triggers a fresh call (2 calls total)" '[ "$(calls)" = "2" ]'
# 5. day rollover and orphan cleanup (happens on a fresh fetch, so expire first)
touch "$CLAUDE_TOKENS_CACHE_DIR/claude-tokens-today-2020-01-01.json"
touch -t 202001010000 "$CLAUDE_TOKENS_CACHE_DIR/claude-tokens-today-$TODAY.json.999"
touch -t 202001010000 "$CLAUDE_TOKENS_CACHE_DIR/claude-tokens-today-$TODAY.json"
run_script >/dev/null
check "yesterday's cache file and stale tmp removed, today's kept" '[ ! -e "$CLAUDE_TOKENS_CACHE_DIR/claude-tokens-today-2020-01-01.json" ] && [ ! -e "$CLAUDE_TOKENS_CACHE_DIR/claude-tokens-today-$TODAY.json.999" ] && [ -s "$CLAUDE_TOKENS_CACHE_DIR/claude-tokens-today-$TODAY.json" ]'

# 5b. plan line: absent, set, malformed, zero (ok fake still exported)
PLANF="$CLAUDE_TOKENS_CONFIG_DIR/plan-usd-month"
check "no plan file: payload carries no plan fields" '! printf "%s" "$A" | grep -q plan'
echo " 200 " > "$PLANF"; clear_cache; PL=$(run_script)
check "plan 200: planUsdMonth 200, planUsdDay 6.67, planPct 18.5 (cost 1.2345)" '[ "$(printf "%s" "$PL" | jq -c "[.planUsdMonth,.planUsdDay,.planPct]")" = "[200,6.67,18.5]" ]'
check "plan fields are appended after the base fields (contract unchanged)" '[ "$(printf "%s" "$PL" | jq -c "del(.planUsdMonth,.planUsdDay,.planPct)")" = "$A" ]'
echo "twenty" > "$PLANF"; clear_cache; PM=$(run_script)
check "malformed plan file: no plan fields, payload otherwise identical" '[ "$PM" = "$A" ]'
echo "0" > "$PLANF"; clear_cache; PZ=$(run_script)
check "plan 0: no plan fields" '[ "$PZ" = "$A" ]'
rm -f "$PLANF"

# 6. empty state
ccusage(){ echo "$*" >> "$COUNT"; echo '{"daily":[],"totals":{}}'; }; export -f ccusage
clear_cache; E=$(run_script)
check "empty payload" '[ "$E" = "{\"status\":\"empty\",\"date\":\"$TODAY\"}" ]'
# 7. period key and null cost
ccusage(){ printf '{"daily":[{"period":"%s","inputTokens":1,"outputTokens":2,"cacheCreationTokens":3,"cacheReadTokens":4,"totalTokens":10,"totalCost":null}]}\n' "$TODAY"; }; export -f ccusage
clear_cache; P=$(run_script)
check ".period day key accepted, null cost becomes 0" '[ "$P" = "{\"status\":\"ok\",\"date\":\"$TODAY\",\"input\":1,\"output\":2,\"cacheRead\":4,\"cacheWrite\":3,\"total\":10,\"cost\":0}" ]'
# 8. error state, never cached
ccusage(){ return 127; }; export -f ccusage
clear_cache; X=$(run_script)
check "error payload when ccusage fails" '[ "$X" = "{\"status\":\"error\",\"message\":\"ccusage not available\"}" ]'
check "error is not cached" '[ ! -e "$CLAUDE_TOKENS_CACHE_DIR/claude-tokens-today-$TODAY.json" ]'
ccusage(){ echo 'not json'; }; export -f ccusage
clear_cache; Y=$(run_script)
check "garbage from ccusage gives the error payload" '[ "$Y" = "{\"status\":\"error\",\"message\":\"ccusage not available\"}" ]'
unset -f ccusage

echo "selftest: $N checks, $FAILS failed"
[ "$FAILS" -eq 0 ]
