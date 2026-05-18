#!/usr/bin/env bash
set -euo pipefail

# GPT Plus / Codex usage provider.
#
# Data source:
# - First tries Codex's ChatGPT plan usage endpoint:
#   https://chatgpt.com/backend-api/wham/usage
#   This returns real primary (5h) and secondary (weekly) plan limit usage for
#   the ChatGPT/Codex account signed in via `codex login`.
# - Falls back to manual values if Codex auth/API is unavailable.
#
# Useful config in ~/.config/sketchybar/ai_usage.env:
#   AI_USAGE_GPT_API_ENABLED=false
#   AI_USAGE_GPT_REMAINING_PERCENT=40
#   AI_USAGE_GPT_MESSAGE="40% left"
#   AI_USAGE_GPT_5H_REMAINING_PERCENT=40
#   AI_USAGE_GPT_5H_RESET_AT="2026-05-12T18:00:00Z"
#   AI_USAGE_GPT_WEEKLY_REMAINING_PERCENT=85
#   AI_USAGE_GPT_WEEKLY_RESET_AT="2026-05-17T00:00:00Z"
#   AI_USAGE_GPT_ENABLED=false
#   AI_USAGE_GPT_STATUS=error

enabled="${AI_USAGE_GPT_ENABLED:-true}"
status_override="${AI_USAGE_GPT_STATUS:-}"
api_enabled="${AI_USAGE_GPT_API_ENABLED:-true}"
compact_remaining="${AI_USAGE_GPT_REMAINING_PERCENT:-}"
compact_message="${AI_USAGE_GPT_MESSAGE:-}"
fiveh_remaining="${AI_USAGE_GPT_5H_REMAINING_PERCENT:-}"
fiveh_message="${AI_USAGE_GPT_5H_MESSAGE:-}"
fiveh_reset_at="${AI_USAGE_GPT_5H_RESET_AT:-}"
weekly_remaining="${AI_USAGE_GPT_WEEKLY_REMAINING_PERCENT:-}"
weekly_message="${AI_USAGE_GPT_WEEKLY_MESSAGE:-}"
weekly_reset_at="${AI_USAGE_GPT_WEEKLY_RESET_AT:-}"

json_null_or_string() {
  local value="$1"
  if [[ -z "$value" ]]; then
    echo null
  else
    jq -Rn --arg value "$value" '$value'
  fi
}

percent_or_null() {
  local value="$1"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "$value"
  else
    echo null
  fi
}

number_or_null() {
  local value="$1"
  if [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "$value"
  else
    echo null
  fi
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

window_status() {
  local value="$1"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    echo ok
  else
    echo unknown
  fi
}

get_codex_access_token() {
  jq -r '.tokens.access_token // empty' "$HOME/.codex/auth.json" 2>/dev/null
}

fetch_codex_usage() {
  local token="$1"
  if [[ -z "$token" || ! -x "$(command -v curl 2>/dev/null)" ]]; then
    return 1
  fi

  local version user_agent
  version="$(codex --version 2>/dev/null | awk '{print $2}' || true)"
  user_agent="codex_cli_rs/${version:-0.128.0}"

  curl -fsS \
    --connect-timeout 5 \
    --max-time 10 \
    -H "Authorization: Bearer $token" \
    -H 'Accept: application/json' \
    -H "User-Agent: $user_agent" \
    'https://chatgpt.com/backend-api/wham/usage' 2>/dev/null
}

emit_codex_usage() {
  local usage_json="$1" plan primary_used secondary_used primary_remaining secondary_remaining primary_reset secondary_reset primary_window secondary_window
  local fiveh_remaining fiveh_used fiveh_reset fiveh_window fiveh_basis weekly_remaining weekly_used weekly_reset weekly_window weekly_basis
  plan="$(jq -r '.plan_type // "unknown"' <<<"$usage_json")"
  primary_used="$(jq -r '.rate_limit.primary_window.used_percent // empty' <<<"$usage_json")"
  secondary_used="$(jq -r '.rate_limit.secondary_window.used_percent // empty' <<<"$usage_json")"
  primary_reset="$(jq -r '.rate_limit.primary_window.reset_at // empty' <<<"$usage_json")"
  secondary_reset="$(jq -r '.rate_limit.secondary_window.reset_at // empty' <<<"$usage_json")"
  primary_window="$(jq -r '.rate_limit.primary_window.limit_window_seconds // empty' <<<"$usage_json")"
  secondary_window="$(jq -r '.rate_limit.secondary_window.limit_window_seconds // empty' <<<"$usage_json")"

  if [[ ! "$primary_used" =~ ^[0-9]+([.][0-9]+)?$ && ! "$secondary_used" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    return 1
  fi

  primary_remaining="null"
  secondary_remaining="null"
  if [[ "$primary_used" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    primary_remaining="$(remaining_from_used_percent "$primary_used")"
  fi
  if [[ "$secondary_used" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    secondary_remaining="$(remaining_from_used_percent "$secondary_used")"
  fi

  fiveh_remaining="null"; fiveh_used="null"; fiveh_reset="null"; fiveh_window="null"; fiveh_basis="official Codex/ChatGPT 5-hour window usage"
  weekly_remaining="null"; weekly_used="null"; weekly_reset="null"; weekly_window="null"; weekly_basis="official Codex/ChatGPT weekly window usage"

  if [[ "$primary_window" == "18000" ]]; then
    fiveh_remaining="$primary_remaining"; fiveh_used="$(number_or_null "$primary_used")"; fiveh_reset="$(number_or_null "$primary_reset")"; fiveh_window="$(number_or_null "$primary_window")"; fiveh_basis="official Codex/ChatGPT primary_window.used_percent"
  elif [[ "$primary_window" == "604800" ]]; then
    weekly_remaining="$primary_remaining"; weekly_used="$(number_or_null "$primary_used")"; weekly_reset="$(number_or_null "$primary_reset")"; weekly_window="$(number_or_null "$primary_window")"; weekly_basis="official Codex/ChatGPT primary_window.used_percent"
  fi

  if [[ "$secondary_window" == "18000" ]]; then
    fiveh_remaining="$secondary_remaining"; fiveh_used="$(number_or_null "$secondary_used")"; fiveh_reset="$(number_or_null "$secondary_reset")"; fiveh_window="$(number_or_null "$secondary_window")"; fiveh_basis="official Codex/ChatGPT secondary_window.used_percent"
  elif [[ "$secondary_window" == "604800" ]]; then
    weekly_remaining="$secondary_remaining"; weekly_used="$(number_or_null "$secondary_used")"; weekly_reset="$(number_or_null "$secondary_reset")"; weekly_window="$(number_or_null "$secondary_window")"; weekly_basis="official Codex/ChatGPT secondary_window.used_percent"
  fi

  jq -n \
    --arg plan "$plan" \
    --argjson remaining "$primary_remaining" \
    --argjson primary_reset "$(number_or_null "$primary_reset")" \
    --argjson fiveh_remaining "$fiveh_remaining" \
    --argjson fiveh_used "$fiveh_used" \
    --argjson fiveh_reset "$fiveh_reset" \
    --argjson fiveh_window "$fiveh_window" \
    --arg fiveh_basis "$fiveh_basis" \
    --argjson weekly_remaining "$weekly_remaining" \
    --argjson weekly_used "$weekly_used" \
    --argjson weekly_reset "$weekly_reset" \
    --argjson weekly_window "$weekly_window" \
    --arg weekly_basis "$weekly_basis" \
    '{
      enabled: true,
      remaining_percent: $remaining,
      reset_at: $primary_reset,
      status: (if $remaining == null then "unknown" else "ok" end),
      message: (if $remaining == null then "Codex usage API missing primary utilization" else (($remaining | tostring) + "% left (official Codex/ChatGPT usage API)") end),
      source: "codex_wham_usage_api",
      is_estimate: false,
      basis: "official Codex/ChatGPT wham usage API",
      plan_type: $plan,
      windows: {
        "5h": {
          remaining_percent: $fiveh_remaining,
          used_percent: $fiveh_used,
          reset_at: $fiveh_reset,
          window_seconds: $fiveh_window,
          status: (if $fiveh_remaining == null then "unknown" else "ok" end),
          message: (if $fiveh_remaining == null then "Codex API missing 5-hour window usage" else (($fiveh_remaining | tostring) + "% left") end),
          is_estimate: false,
          basis: $fiveh_basis
        },
        weekly: {
          remaining_percent: $weekly_remaining,
          used_percent: $weekly_used,
          reset_at: $weekly_reset,
          window_seconds: $weekly_window,
          status: (if $weekly_remaining == null then "unknown" else "ok" end),
          message: (if $weekly_remaining == null then "Codex API missing weekly window usage" else (($weekly_remaining | tostring) + "% left") end),
          is_estimate: false,
          basis: $weekly_basis
        }
      }
    }'
}

if [[ "$enabled" == "0" || "$enabled" == "false" || "$enabled" == "no" ]]; then
  jq -n '{enabled: false, remaining_percent: null, reset_at: null, status: "disabled", message: "disabled", source: "manual", windows: {"5h": {remaining_percent: null, reset_at: null, status: "disabled", message: "disabled"}, weekly: {remaining_percent: null, reset_at: null, status: "disabled", message: "disabled"}}}'
  exit 0
fi

if [[ -n "$status_override" && "$status_override" != "ok" ]]; then
  jq -n \
    --arg status "$status_override" \
    --arg message "${compact_message:-$status_override}" \
    '{enabled: true, remaining_percent: null, reset_at: null, status: $status, message: $message, source: "manual", windows: {"5h": {remaining_percent: null, reset_at: null, status: $status, message: $message}, weekly: {remaining_percent: null, reset_at: null, status: $status, message: $message}}}'
  exit 0
fi

if [[ "$api_enabled" != "0" && "$api_enabled" != "false" && "$api_enabled" != "no" ]]; then
  codex_token="$(get_codex_access_token || true)"
  codex_usage="$(fetch_codex_usage "$codex_token" || true)"
  if jq -e . >/dev/null 2>&1 <<<"$codex_usage" && emit_codex_usage "$codex_usage"; then
    exit 0
  fi
fi

# If compact value is not set, prefer the 5h manual value for the bar label.
top_remaining="$(percent_or_null "$compact_remaining")"
if [[ "$top_remaining" == "null" ]]; then
  top_remaining="$(percent_or_null "$fiveh_remaining")"
fi

top_status="$(window_status "$top_remaining")"
if [[ "$top_remaining" == "null" ]]; then
  top_status="unknown"
fi

basis="manual user-provided GPT Plus remaining value"
if [[ "$top_status" == "ok" ]]; then
  top_message="${compact_message:-≈${top_remaining}% left (${basis})}"
else
  top_message="Codex usage API unavailable; configure AI_USAGE_GPT_REMAINING_PERCENT or AI_USAGE_GPT_5H_REMAINING_PERCENT"
fi

fiveh_json_remaining="$(percent_or_null "$fiveh_remaining")"
weekly_json_remaining="$(percent_or_null "$weekly_remaining")"
fiveh_status="$(window_status "$fiveh_json_remaining")"
weekly_status="$(window_status "$weekly_json_remaining")"
if [[ "$fiveh_json_remaining" == "null" ]]; then fiveh_status="unknown"; fi
if [[ "$weekly_json_remaining" == "null" ]]; then weekly_status="unknown"; fi

fiveh_message="$(if [[ "$fiveh_status" == ok ]]; then echo "${fiveh_message:-≈${fiveh_json_remaining}% left}"; else echo "configure GPT 5h manual remaining"; fi)"
weekly_message="$(if [[ "$weekly_status" == ok ]]; then echo "${weekly_message:-≈${weekly_json_remaining}% left}"; else echo "configure GPT weekly manual remaining"; fi)"

jq -n \
  --argjson remaining "$top_remaining" \
  --arg status "$top_status" \
  --arg message "$top_message" \
  --arg basis "$basis" \
  --argjson fiveh_remaining "$fiveh_json_remaining" \
  --arg fiveh_status "$fiveh_status" \
  --arg fiveh_message "$fiveh_message" \
  --arg fiveh_basis "$basis" \
  --argjson fiveh_reset_at "$(json_null_or_string "$fiveh_reset_at")" \
  --argjson weekly_remaining "$weekly_json_remaining" \
  --arg weekly_status "$weekly_status" \
  --arg weekly_message "$weekly_message" \
  --arg weekly_basis "$basis" \
  --argjson weekly_reset_at "$(json_null_or_string "$weekly_reset_at")" \
  '{
    enabled: true,
    remaining_percent: $remaining,
    reset_at: $fiveh_reset_at,
    status: $status,
    message: $message,
    source: "manual",
    is_estimate: ($status == "ok"),
    basis: (if $status == "ok" then $basis else null end),
    windows: {
      "5h": {
        remaining_percent: $fiveh_remaining,
        reset_at: $fiveh_reset_at,
        status: $fiveh_status,
        message: $fiveh_message,
        is_estimate: ($fiveh_status == "ok"),
        basis: (if $fiveh_status == "ok" then $fiveh_basis else null end)
      },
      weekly: {
        remaining_percent: $weekly_remaining,
        reset_at: $weekly_reset_at,
        status: $weekly_status,
        message: $weekly_message,
        is_estimate: ($weekly_status == "ok"),
        basis: (if $weekly_status == "ok" then $weekly_basis else null end)
      }
    }
  }'
