command: """
  export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
  TODAY=$(date +%Y-%m-%d)
  SINCE=$(date -v-1d +%Y%m%d 2>/dev/null || date -d yesterday +%Y%m%d)
  DIR="${CLAUDE_TOKENS_CACHE_DIR:-$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || echo "${TMPDIR:-/tmp}")}"
  CACHE="$DIR/claude-tokens-today-$TODAY.json"
  if [ -s "$CACHE" ]; then
    AGE=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || stat -f %m "$CACHE") ))
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
  # Optional plan line: ~/.config/claude-tokens/plan-usd-month holds one number
  # (what the subscription costs per month); the payload then carries plan/day
  # (30-day month) and today's API-equivalent cost as a percentage of it.
  # Absent, zero or malformed means no plan fields at all, never a wrong one.
  PLAN=$(cat "${CLAUDE_TOKENS_CONFIG_DIR:-$HOME/.config/claude-tokens}/plan-usd-month" 2>/dev/null | tr -d '[:space:]')
  OUT=$(ccusage claude daily --json --since "$SINCE" --offline 2>/dev/null | jq -c --arg t "$TODAY" --arg plan "$PLAN" '
    ((.daily // []) | map(select((.date // .period) == $t)) | .[0]) as $d
    | (try ($plan | tonumber) catch 0) as $p
    | if $d == null then {status:"empty", date:$t}
      else {status:"ok", date:$t,
            input:($d.inputTokens // 0), output:($d.outputTokens // 0),
            cacheRead:($d.cacheReadTokens // 0), cacheWrite:($d.cacheCreationTokens // 0),
            total:($d.totalTokens // 0), cost:($d.totalCost // 0)}
           + (if $p > 0 then {planUsdMonth:$p, planUsdDay:(($p / 30 * 100 | round) / 100),
                              planPct:((($d.totalCost // 0) / ($p / 30) * 1000 | round) / 10)} else {} end) end' 2>/dev/null)
  if [ -n "$OUT" ]; then
    (umask 077; echo "$OUT" > "$CACHE.$$" && mv -f "$CACHE.$$" "$CACHE") 2>/dev/null
    find "$DIR" -maxdepth 1 '(' -name 'claude-tokens-today-*.json' ! -name "claude-tokens-today-$TODAY.json" -o -name 'claude-tokens-today-*.json.*' -mmin +5 ')' -delete 2>/dev/null
    echo "$OUT"
  else
    echo '{"status":"error","message":"ccusage not available"}'
  fi
"""

refreshFrequency: 30000

display: 'main'

render: (output) -> """
  <div class='widget-card'>
    <div class='header'>
      <div class='icon'><svg viewBox="0 0 96 96" width="26" height="26"><rect x="15" y="71" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="15" y="61" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="37" y="71" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="37" y="61" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="37" y="51" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="37" y="41" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="59" y="71" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="59" y="61" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="59" y="51" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="59" y="41" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="59" y="31" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="59" y="21" width="22" height="7" rx="3.5" fill="#CFDFE8"/><rect x="59" y="8" width="22" height="7" rx="3.5" fill="#F3F1EB" transform="rotate(-12 70 11.5)"/></svg></div>
      <div class='title'>Claude Code Today</div>
    </div>
    <div class='main-number' id='main'>--</div>
    <div class='subtitle' id='subtitle'>loading...</div>
    <div class='breakdown' id='breakdown'></div>
  </div>
"""

update: (output, domEl) ->
  try
    data = JSON.parse(output)
  catch e
    domEl.querySelector('#main').textContent = 'ERR'
    domEl.querySelector('#subtitle').textContent = 'parse failed'
    return

  if data.status == 'error'
    domEl.querySelector('#main').textContent = '!'
    domEl.querySelector('#subtitle').textContent = data.message
    return

  if data.status == 'empty'
    domEl.querySelector('#main').textContent = '0'
    domEl.querySelector('#subtitle').textContent = "No usage on #{data.date}"
    domEl.querySelector('#breakdown').innerHTML = ''
    return

  total = data.total
  display = if total >= 1000000 then "#{(total/1000000).toFixed(2)}M"
  else if total >= 1000 then "#{(total/1000).toFixed(1)}k"
  else "#{total}"

  fmt = (n) -> n.toLocaleString('en-US')

  domEl.querySelector('#main').textContent = display
  now = new Date()
  timeStr = now.toLocaleTimeString('en-US', {hour12: false})
  domEl.querySelector('#subtitle').innerHTML = "tokens today · #{data.date}<br><span style='opacity:0.6; font-size:11px'>updated #{timeStr}</span>"
  domEl.querySelector('#breakdown').innerHTML = """
    <div class='row'><span>Input</span><span>#{fmt(data.input)}</span></div>
    <div class='row'><span>Output</span><span>#{fmt(data.output)}</span></div>
    <div class='row'><span>Cache create</span><span>#{fmt(data.cacheWrite)}</span></div>
    <div class='row'><span>Cache read</span><span>#{fmt(data.cacheRead)}</span></div>
    <div class='row total'><span>Total</span><span>#{fmt(data.total)}</span></div>
    <div class='row cost'><span>API equiv.</span><span>$#{data.cost.toFixed(2)}</span></div>
  """
  if data.planUsdDay?
    domEl.querySelector('#breakdown').innerHTML += """
      <div class='row plan'><span>Plan ROI</span><span>#{data.planPct}% of $#{data.planUsdDay.toFixed(2)}/day</span></div>
    """

# STYLE: position first (use top OR bottom, left OR right; height is
# automatic), then every element on the card. No semicolons in this block:
# it is CoffeeScript, and indentation is significant. The font-family line
# is the shared stack used by all four desktop widgets (SF Pro, the macOS
# system font); font-variant-numeric gives digits equal width so columns
# of numbers line up.
style: """
  bottom: 180px
  left: 15px
  font-family: -apple-system, 'SF Pro Display', 'Helvetica Neue', sans-serif
  font-variant-numeric: tabular-nums
  -webkit-font-smoothing: antialiased
  color: #fff

  .widget-card
    background: rgba(20, 20, 24, 0.78)
    backdrop-filter: blur(24px) saturate(180%)
    -webkit-backdrop-filter: blur(24px) saturate(180%)
    border: 1px solid rgba(255, 255, 255, 0.08)
    border-radius: 18px
    padding: 18px 20px
    width: 305px
    box-shadow: 0 12px 40px rgba(0, 0, 0, 0.35)

  .header
    display: flex
    align-items: center
    gap: 8px
    margin-bottom: 10px

  .icon svg
    display: block

  .title
    font-size: 14px
    font-weight: 500
    letter-spacing: 0.3px
    text-transform: uppercase
    color: rgba(255, 255, 255, 0.6)

  .main-number
    font-size: 48px
    font-weight: 700
    letter-spacing: -1px
    line-height: 1
    color: #fff

  .subtitle
    font-size: 14px
    color: rgba(255, 255, 255, 0.5)
    margin-top: 4px
    margin-bottom: 14px

  .breakdown
    border-top: 1px solid rgba(255, 255, 255, 0.08)
    padding-top: 12px

  .row
    display: flex
    justify-content: space-between
    font-size: 12px
    padding: 3px 0
    color: rgba(255, 255, 255, 0.75)

  .row.total
    border-top: 1px solid rgba(255, 255, 255, 0.08)
    margin-top: 6px
    padding-top: 8px
    font-weight: 600
    color: #fff

  .row.cost, .row.plan
    color: rgba(255, 255, 255, 0.45)
    font-size: 11px
"""
