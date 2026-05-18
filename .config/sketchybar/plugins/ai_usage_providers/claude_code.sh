#!/usr/bin/env bash
set -euo pipefail

# Claude Code usage provider.
#
# Data source:
# - First tries the Claude OAuth usage API used by Claude Code:
#   https://api.anthropic.com/api/oauth/usage
#   This returns official plan-limit utilization for five_hour and seven_day.
# - Falls back to `ccusage` (`ccusage` binary if installed, otherwise `npx
#   ccusage`) if the API/token is unavailable.
#
# Useful config in ~/.config/sketchybar/ai_usage.env:
#   AI_USAGE_CLAUDE_5H_TOKEN_LIMIT=100000000
#   AI_USAGE_CLAUDE_WEEKLY_TOKEN_LIMIT=1000000000
#   AI_USAGE_CLAUDE_5H_COST_LIMIT=50
#   AI_USAGE_CLAUDE_WEEKLY_COST_LIMIT=500
#   AI_USAGE_CLAUDE_LIMIT_MODE=tokens        # tokens or cost, default tokens
#   AI_USAGE_CLAUDE_ENABLED=false
#   AI_USAGE_CLAUDE_STATUS=error
#
# Disable the official OAuth usage API and use fallbacks only:
#   AI_USAGE_CLAUDE_API_ENABLED=false
#
# Claude UI plan-limit overrides. These win over ccusage estimates, but the
# official OAuth usage API wins over these when available:
#   AI_USAGE_CLAUDE_5H_USED_PERCENT=13
#   AI_USAGE_CLAUDE_5H_RESET_AT="in 11 min"
#   AI_USAGE_CLAUDE_WEEKLY_USED_PERCENT=10
#   AI_USAGE_CLAUDE_WEEKLY_RESET_AT="Thu 9:00 AM"
#
# Legacy/manual compact override is still supported:
#   AI_USAGE_CLAUDE_REMAINING_PERCENT=72
#   AI_USAGE_CLAUDE_MESSAGE="72% left · resets 14:30"

enabled="${AI_USAGE_CLAUDE_ENABLED:-true}"
status_override="${AI_USAGE_CLAUDE_STATUS:-}"
legacy_remaining="${AI_USAGE_CLAUDE_REMAINING_PERCENT:-}"
legacy_message="${AI_USAGE_CLAUDE_MESSAGE:-}"
limit_mode="${AI_USAGE_CLAUDE_LIMIT_MODE:-tokens}"
api_enabled="${AI_USAGE_CLAUDE_API_ENABLED:-true}"

if [[ "$enabled" == "0" || "$enabled" == "false" || "$enabled" == "no" ]]; then
  jq -n '{enabled: false, remaining_percent: null, reset_at: null, status: "disabled", message: "disabled"}'
  exit 0
fi

if [[ -n "$status_override" && "$status_override" != "ok" ]]; then
  jq -n \
    --arg status "$status_override" \
    --arg message "${legacy_message:-$status_override}" \
    '{enabled: true, remaining_percent: null, reset_at: null, status: $status, message: $message}'
  exit 0
fi

run_ccusage() {
  if command -v ccusage >/dev/null 2>&1; then
    ccusage "$@" --json --offline 2>/dev/null
  elif command -v npx >/dev/null 2>&1; then
    npx ccusage "$@" --json --offline 2>/dev/null
  else
    return 127
  fi
}

get_claude_oauth_token() {
  if ! command -v security >/dev/null 2>&1; then
    return 1
  fi
  security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null
}

fetch_oauth_usage() {
  local token="$1"
  if [[ -z "$token" || ! -x "$(command -v curl 2>/dev/null)" ]]; then
    return 1
  fi
  local version user_agent
  version="$(claude --version 2>/dev/null | awk '{print $1}' || true)"
  user_agent="claude-code/${version:-2.1.139}"

  curl -fsS \
    --connect-timeout 5 \
    --max-time 10 \
    -H "Authorization: Bearer $token" \
    -H 'Accept: application/json' \
    -H "User-Agent: $user_agent" \
    'https://api.anthropic.com/api/oauth/usage' 2>/dev/null
}

remaining_from_used_percent() {
  local used_percent="$1"
  awk -v used="$used_percent" 'BEGIN {
    remaining = 100 - used
    if (remaining < 0) remaining = 0
    if (remaining > 100) remaining = 100
    printf "%d", remaining + 0.5
  }'
}

emit_oauth_usage() {
  local usage_json="$1" fiveh_used weekly_used fiveh_remaining weekly_remaining fiveh_reset_at weekly_reset_at
  fiveh_used="$(jq -r '.five_hour.utilization // empty' <<<"$usage_json")"
  weekly_used="$(jq -r '.seven_day.utilization // empty' <<<"$usage_json")"
  fiveh_reset_at="$(jq -r '.five_hour.resets_at // empty' <<<"$usage_json")"
  weekly_reset_at="$(jq -r '.seven_day.resets_at // empty' <<<"$usage_json")"

  if [[ ! "$fiveh_used" =~ ^[0-9]+([.][0-9]+)?$ && ! "$weekly_used" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    return 1
  fi

  fiveh_remaining="null"
  weekly_remaining="null"
  if [[ "$fiveh_used" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    fiveh_remaining="$(remaining_from_used_percent "$fiveh_used")"
  fi
  if [[ "$weekly_used" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    weekly_remaining="$(remaining_from_used_percent "$weekly_used")"
  fi

  jq -n \
    --argjson remaining "$fiveh_remaining" \
    --arg reset_at "${fiveh_reset_at:-}" \
    --argjson fiveh_remaining "$fiveh_remaining" \
    --arg fiveh_reset_at "${fiveh_reset_at:-}" \
    --argjson fiveh_used "$fiveh_used" \
    --argjson weekly_remaining "$weekly_remaining" \
    --arg weekly_reset_at "${weekly_reset_at:-}" \
    --argjson weekly_used "$weekly_used" \
    '{
      enabled: true,
      remaining_percent: $remaining,
      reset_at: (if $reset_at == "" then null else $reset_at end),
      status: (if $remaining == null then "unknown" else "ok" end),
      message: (if $remaining == null then "Claude OAuth usage API missing five_hour utilization" else (($remaining | tostring) + "% left (official Claude usage API)") end),
      source: "claude_oauth_usage_api",
      is_estimate: false,
      basis: "official Claude OAuth usage API utilization",
      windows: {
        "5h": {
          remaining_percent: $fiveh_remaining,
          used_percent: $fiveh_used,
          reset_at: (if $fiveh_reset_at == "" then null else $fiveh_reset_at end),
          status: (if $fiveh_remaining == null then "unknown" else "ok" end),
          message: (if $fiveh_remaining == null then "OAuth API missing five_hour utilization" else (($fiveh_remaining | tostring) + "% left") end),
          is_estimate: false,
          basis: "official Claude OAuth usage API five_hour.utilization"
        },
        weekly: {
          remaining_percent: $weekly_remaining,
          used_percent: $weekly_used,
          reset_at: (if $weekly_reset_at == "" then null else $weekly_reset_at end),
          status: (if $weekly_remaining == null then "unknown" else "ok" end),
          message: (if $weekly_remaining == null then "OAuth API missing seven_day utilization" else (($weekly_remaining | tostring) + "% left") end),
          is_estimate: false,
          basis: "official Claude OAuth usage API seven_day.utilization"
        }
      }
    }'
}

percent_remaining() {
  local used="$1" limit="$2"
  awk -v used="$used" -v limit="$limit" 'BEGIN {
    if (limit <= 0) { print "null"; exit }
    remaining = 100 - ((used / limit) * 100)
    if (remaining < 0) remaining = 0
    if (remaining > 100) remaining = 100
    printf "%d", remaining + 0.5
  }'
}

window_status() {
  local remaining="$1"
  if [[ "$remaining" =~ ^[0-9]+$ ]]; then
    echo ok
  else
    echo unknown
  fi
}

reset_weekly_at() {
  local week_start="$1"
  if [[ -z "$week_start" || "$week_start" == "null" ]]; then
    echo null
  elif command -v node >/dev/null 2>&1; then
    local reset_at
    if reset_at="$(node -e 'const d = new Date(process.argv[1] + "T00:00:00Z"); if (Number.isNaN(d.getTime())) process.stdout.write("null"); else { d.setUTCDate(d.getUTCDate() + 7); process.stdout.write(JSON.stringify(d.toISOString().replace(/\.000Z$/, "Z"))); }' "$week_start" 2>/dev/null)"; then
      printf '%s\n' "$reset_at"
    else
      echo null
    fi
  else
    echo null
  fi
}

if [[ "$api_enabled" != "0" && "$api_enabled" != "false" && "$api_enabled" != "no" ]]; then
  oauth_token="$(get_claude_oauth_token || true)"
  oauth_usage="$(fetch_oauth_usage "$oauth_token" || true)"
  if ! jq -e . >/dev/null 2>&1 <<<"$oauth_usage" && command -v claude >/dev/null 2>&1; then
    claude auth status >/dev/null 2>&1 || true
    oauth_token="$(get_claude_oauth_token || true)"
    oauth_usage="$(fetch_oauth_usage "$oauth_token" || true)"
  fi
  if jq -e . >/dev/null 2>&1 <<<"$oauth_usage" && emit_oauth_usage "$oauth_usage"; then
    exit 0
  fi
fi

blocks_json="$(run_ccusage blocks || true)"
weekly_json="$(run_ccusage weekly || true)"

if ! jq -e . >/dev/null 2>&1 <<<"$blocks_json"; then
  if [[ "$legacy_remaining" =~ ^[0-9]+$ ]]; then
    jq -n \
      --argjson remaining "$legacy_remaining" \
      --arg message "${legacy_message:-${legacy_remaining}% left}" \
      '{enabled: true, remaining_percent: $remaining, reset_at: null, status: "ok", message: $message}'
  else
    jq -n '{enabled: true, remaining_percent: null, reset_at: null, status: "error", message: "ccusage unavailable"}'
  fi
  exit 0
fi

active_block="$(jq -c '(.blocks // []) | map(select(.isActive == true)) | sort_by(.startTime) | last // null' <<<"$blocks_json")"
latest_block="$(jq -c '(.blocks // []) | sort_by(.startTime) | last // null' <<<"$blocks_json")"
block="$active_block"
if [[ "$block" == "null" ]]; then
  block="$latest_block"
fi

fiveh_used_tokens="$(jq -r '.totalTokens // 0' <<<"$block")"
fiveh_used_cost="$(jq -r '.costUSD // 0' <<<"$block")"
fiveh_reset_at="$(jq -r '.endTime // empty' <<<"$block")"

weekly="null"
if jq -e . >/dev/null 2>&1 <<<"$weekly_json"; then
  weekly="$(jq -c '(.weekly // []) | sort_by(.week) | last // null' <<<"$weekly_json")"
fi
weekly_used_tokens="$(jq -r '.totalTokens // 0' <<<"$weekly")"
weekly_used_cost="$(jq -r '.totalCost // 0' <<<"$weekly")"
weekly_start="$(jq -r '.week // empty' <<<"$weekly")"
weekly_reset_at="$(reset_weekly_at "$weekly_start")"

if [[ "$limit_mode" == "cost" ]]; then
  fiveh_limit="${AI_USAGE_CLAUDE_5H_COST_LIMIT:-}"
  weekly_limit="${AI_USAGE_CLAUDE_WEEKLY_COST_LIMIT:-}"
  fiveh_used="$fiveh_used_cost"
  weekly_used="$weekly_used_cost"
  unit="USD"
else
  fiveh_limit="${AI_USAGE_CLAUDE_5H_TOKEN_LIMIT:-}"
  weekly_limit="${AI_USAGE_CLAUDE_WEEKLY_TOKEN_LIMIT:-}"
  fiveh_used="$fiveh_used_tokens"
  weekly_used="$weekly_used_tokens"
  unit="tokens"
fi

fiveh_remaining="null"
weekly_remaining="null"
fiveh_basis="ccusage used ${unit} / configured local ${unit} limit"
weekly_basis="ccusage used ${unit} / configured local ${unit} limit"
if [[ "$fiveh_limit" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  fiveh_remaining="$(percent_remaining "$fiveh_used" "$fiveh_limit")"
fi
if [[ "$weekly_limit" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  weekly_remaining="$(percent_remaining "$weekly_used" "$weekly_limit")"
fi

if [[ "${AI_USAGE_CLAUDE_5H_REMAINING_PERCENT:-}" =~ ^[0-9]+$ ]]; then
  fiveh_remaining="$AI_USAGE_CLAUDE_5H_REMAINING_PERCENT"
  fiveh_basis="manual Claude plan limits UI remaining percent"
elif [[ "${AI_USAGE_CLAUDE_5H_USED_PERCENT:-}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  fiveh_remaining="$(remaining_from_used_percent "$AI_USAGE_CLAUDE_5H_USED_PERCENT")"
  fiveh_basis="manual Claude plan limits UI used percent"
fi
if [[ -n "${AI_USAGE_CLAUDE_5H_RESET_AT:-}" ]]; then
  fiveh_reset_at="$AI_USAGE_CLAUDE_5H_RESET_AT"
fi

if [[ "${AI_USAGE_CLAUDE_WEEKLY_REMAINING_PERCENT:-}" =~ ^[0-9]+$ ]]; then
  weekly_remaining="$AI_USAGE_CLAUDE_WEEKLY_REMAINING_PERCENT"
  weekly_basis="manual Claude plan limits UI remaining percent"
elif [[ "${AI_USAGE_CLAUDE_WEEKLY_USED_PERCENT:-}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  weekly_remaining="$(remaining_from_used_percent "$AI_USAGE_CLAUDE_WEEKLY_USED_PERCENT")"
  weekly_basis="manual Claude plan limits UI used percent"
fi
if [[ -n "${AI_USAGE_CLAUDE_WEEKLY_RESET_AT:-}" ]]; then
  weekly_reset_at="$(jq -Rn --arg reset "$AI_USAGE_CLAUDE_WEEKLY_RESET_AT" '$reset')"
fi

# Manual compact override wins for the top-level value only. Window rows reflect
# Claude UI overrides when provided, otherwise ccusage + configured limits.
top_remaining="$fiveh_remaining"
top_status="$(window_status "$fiveh_remaining")"
if [[ "$legacy_remaining" =~ ^[0-9]+$ ]]; then
  top_remaining="$legacy_remaining"
  top_status="ok"
fi

limit_mode_upper="$(printf '%s' "$limit_mode" | tr '[:lower:]' '[:upper:]')"
if [[ "$limit_mode_upper" == "TOKENS" ]]; then
  limit_mode_upper="TOKEN"
fi
basis="$fiveh_basis"
if [[ "$top_status" == "ok" ]]; then
  top_message="${legacy_message:-≈${top_remaining}% left (${basis})}"
else
  top_message="ccusage found; configure AI_USAGE_CLAUDE_5H_${limit_mode_upper}_LIMIT"
fi

fiveh_status="$(window_status "$fiveh_remaining")"
weekly_status="$(window_status "$weekly_remaining")"
fiveh_message="$(if [[ "$fiveh_status" == ok ]]; then echo "≈${fiveh_remaining}% left"; else echo "configure 5h ${unit} limit"; fi)"
weekly_message="$(if [[ "$weekly_status" == ok ]]; then echo "≈${weekly_remaining}% left"; else echo "configure weekly ${unit} limit"; fi)"

jq -n \
  --argjson remaining "$top_remaining" \
  --arg status "$top_status" \
  --arg message "$top_message" \
  --arg basis "$basis" \
  --arg reset_at "${fiveh_reset_at:-}" \
  --argjson fiveh_remaining "$fiveh_remaining" \
  --arg fiveh_status "$fiveh_status" \
  --arg fiveh_message "$fiveh_message" \
  --arg fiveh_basis "$fiveh_basis" \
  --arg fiveh_reset_at "${fiveh_reset_at:-}" \
  --argjson fiveh_used_tokens "$fiveh_used_tokens" \
  --argjson fiveh_used_cost "$fiveh_used_cost" \
  --argjson weekly_remaining "$weekly_remaining" \
  --arg weekly_status "$weekly_status" \
  --arg weekly_message "$weekly_message" \
  --arg weekly_basis "$weekly_basis" \
  --argjson weekly_reset_at "$weekly_reset_at" \
  --argjson weekly_used_tokens "$weekly_used_tokens" \
  --argjson weekly_used_cost "$weekly_used_cost" \
  '{
    enabled: true,
    remaining_percent: $remaining,
    reset_at: (if $reset_at == "" then null else $reset_at end),
    status: $status,
    message: $message,
    source: "ccusage",
    is_estimate: ($status == "ok"),
    basis: (if $status == "ok" then $basis else null end),
    windows: {
      "5h": {
        remaining_percent: $fiveh_remaining,
        reset_at: (if $fiveh_reset_at == "" then null else $fiveh_reset_at end),
        status: $fiveh_status,
        message: $fiveh_message,
        is_estimate: ($fiveh_status == "ok"),
        basis: (if $fiveh_status == "ok" then $fiveh_basis else null end),
        used_tokens: $fiveh_used_tokens,
        used_cost_usd: $fiveh_used_cost
      },
      weekly: {
        remaining_percent: $weekly_remaining,
        reset_at: $weekly_reset_at,
        status: $weekly_status,
        message: $weekly_message,
        is_estimate: ($weekly_status == "ok"),
        basis: (if $weekly_status == "ok" then $weekly_basis else null end),
        used_tokens: $weekly_used_tokens,
        used_cost_usd: $weekly_used_cost
      }
    }
  }'
