command: """
  export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
  TODAY=$(date +%Y-%m-%d)
  JSON=$(ccusage daily --json 2>/dev/null)
  if [ -z "$JSON" ]; then
    echo '{"status":"error","message":"ccusage not available"}'
    exit 0
  fi
  TODAY_DATA=$(echo "$JSON" | jq -r --arg today "$TODAY" '.daily[] | select((.date // .period) == $today)')
  if [ -z "$TODAY_DATA" ]; then
    echo "{\\"status\\":\\"empty\\",\\"date\\":\\"$TODAY\\"}"
    exit 0
  fi
  INPUT=$(echo "$TODAY_DATA" | jq -r '.inputTokens // 0')
  OUTPUT=$(echo "$TODAY_DATA" | jq -r '.outputTokens // 0')
  CACHE_READ=$(echo "$TODAY_DATA" | jq -r '.cacheReadTokens // 0')
  CACHE_WRITE=$(echo "$TODAY_DATA" | jq -r '.cacheCreationTokens // 0')
  TOTAL=$(echo "$TODAY_DATA" | jq -r '.totalTokens // 0')
  COST=$(echo "$TODAY_DATA" | jq -r '.totalCost // 0')
  echo "{\\"status\\":\\"ok\\",\\"date\\":\\"$TODAY\\",\\"input\\":$INPUT,\\"output\\":$OUTPUT,\\"cacheRead\\":$CACHE_READ,\\"cacheWrite\\":$CACHE_WRITE,\\"total\\":$TOTAL,\\"cost\\":$COST}"
"""

refreshFrequency: 30000

display: 'main'

render: (output) -> """
  <div class='widget-card'>
    <div class='header'>
      <div class='icon'><svg viewBox="0 0 96 96" width="26" height="26"><rect x="15" y="71" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="15" y="61" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="37" y="71" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="37" y="61" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="37" y="51" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="37" y="41" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="59" y="71" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="59" y="61" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="59" y="51" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="59" y="41" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="59" y="31" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="59" y="21" width="22" height="7" rx="3.5" fill="#2FD4C4"/><rect x="59" y="8" width="22" height="7" rx="3.5" fill="#F7F5F2" transform="rotate(-12 70 11.5)"/></svg></div>
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

style: """
  bottom: 180px
  left: 15px
  font-family: -apple-system, 'SF Pro Display', system-ui, sans-serif
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

  .row.cost
    color: rgba(255, 255, 255, 0.45)
    font-size: 11px
"""
