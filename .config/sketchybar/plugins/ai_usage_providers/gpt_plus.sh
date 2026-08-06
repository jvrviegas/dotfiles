#!/usr/bin/env bash
set -euo pipefail

# GPT Plus / Codex usage provider.
#
# Data source:
# - First tries Codex's ChatGPT plan usage endpoint:
#   https://chatgpt.com/backend-api/wham/usage
#   This returns real primary (5h) and secondary (weekly) plan limit usage for
#   the ChatGPT/Codex account signed in via `codex login`, and may also return
#   a credits balance for credit-based accounts.
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
#   AI_USAGE_GPT_CREDITS_BALANCE=123.45
#   AI_USAGE_GPT_CREDITS_UNLIMITED=false
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
credits_balance="${AI_USAGE_GPT_CREDITS_BALANCE:-}"
credits_unlimited="${AI_USAGE_GPT_CREDITS_UNLIMITED:-}"
credits_has_credits="${AI_USAGE_GPT_CREDITS_HAS_CREDITS:-}"
credits_message_override="${AI_USAGE_GPT_CREDITS_MESSAGE:-}"

json_null_or_string() {
  local value="$1"
  if [[ -z "$value" || "$value" == "null" ]]; then
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

lower_value() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

bool_or_null() {
  local value
  value="$(lower_value "$1")"
  case "$value" in
    true|1|yes|y|on) echo true ;;
    false|0|no|n|off) echo false ;;
    *) echo null ;;
  esac
}

truthy() {
  local value
  value="$(lower_value "$1")"
  [[ "$value" == "true" || "$value" == "1" || "$value" == "yes" || "$value" == "y" || "$value" == "on" ]]
}

falsey() {
  local value
  value="$(lower_value "$1")"
  [[ "$value" == "false" || "$value" == "0" || "$value" == "no" || "$value" == "n" || "$value" == "off" ]]
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

format_credit_balance() {
  local balance="$1"
  if [[ ! "$balance" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf '%s' "$balance"
    return 0
  fi

  awk -v balance="$balance" 'BEGIN {
    if (balance >= 100) {
      printf "%d", balance
    } else if (balance >= 10) {
      printf "%.1f", balance
    } else {
      printf "%.2f", balance
    }
  }' | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'
}

credit_effective_has() {
  local has_credits="$1" unlimited="$2" balance="$3"
  if falsey "$has_credits"; then
    echo false
  elif truthy "$has_credits" || truthy "$unlimited" || [[ -n "$balance" && "$balance" != "null" ]]; then
    echo true
  else
    echo false
  fi
}

credit_status() {
  local has_credits="$1" unlimited="$2" balance="$3" spend_reached="$4"
  if [[ "$has_credits" != "true" ]]; then
    echo unknown
  elif truthy "$spend_reached"; then
    echo error
  else
    echo ok
  fi
}

credit_compact_label() {
  local has_credits="$1" unlimited="$2" balance="$3"
  if [[ "$has_credits" != "true" ]]; then
    return 0
  fi
  if truthy "$unlimited"; then
    printf '∞cr'
  elif [[ -n "$balance" && "$balance" != "null" ]]; then
    printf '%scr' "$(format_credit_balance "$balance")"
  else
    printf 'cr'
  fi
}

credit_display_label() {
  local has_credits="$1" unlimited="$2" balance="$3"
  if [[ "$has_credits" != "true" ]]; then
    return 0
  fi
  if truthy "$unlimited"; then
    printf 'Unlimited credits'
  elif [[ -n "$balance" && "$balance" != "null" ]]; then
    printf '%s credits' "$(format_credit_balance "$balance")"
  else
    printf 'Credit usage active'
  fi
}

credit_color() {
  local status="$1" unlimited="${2:-}" balance="${3:-}"
  case "$status" in
    error)
      echo red
      ;;
    ok)
      if truthy "$unlimited"; then
        echo green
      elif [[ "$balance" =~ ^[0-9]+([.][0-9]+)?$ ]] && awk -v balance="$balance" 'BEGIN { exit !(balance <= 0) }'; then
        echo red
      else
        echo green
      fi
      ;;
    *)
      echo grey
      ;;
  esac
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
  local usage_json="$1"
  local plan primary_used secondary_used primary_remaining secondary_remaining primary_reset secondary_reset primary_window secondary_window
  local fiveh_remaining fiveh_used fiveh_reset fiveh_window fiveh_basis weekly_remaining weekly_used weekly_reset weekly_window weekly_basis
  local has_rate_limit credits_has credits_unlimited_api credits_balance_api credits_balance_from_manual credits_overage_reached spend_reached effective_credits_has credits_limit_reached credits_status_value
  local credits_compact credits_display credits_message credits_basis credits_color_value credits_is_estimate credits_has_json credits_unlimited_json credits_balance_json
  local top_remaining top_reset top_status top_message top_basis top_display_label top_display_color top_is_estimate
  local top_display_label_json top_display_color_json credits_display_json credits_compact_json

  plan="$(jq -r '.plan_type // "unknown"' <<<"$usage_json")"
  primary_used="$(jq -r '.rate_limit.primary_window.used_percent // empty' <<<"$usage_json")"
  secondary_used="$(jq -r '.rate_limit.secondary_window.used_percent // empty' <<<"$usage_json")"
  primary_reset="$(jq -r '.rate_limit.primary_window.reset_at // empty' <<<"$usage_json")"
  secondary_reset="$(jq -r '.rate_limit.secondary_window.reset_at // empty' <<<"$usage_json")"
  primary_window="$(jq -r '.rate_limit.primary_window.limit_window_seconds // empty' <<<"$usage_json")"
  secondary_window="$(jq -r '.rate_limit.secondary_window.limit_window_seconds // empty' <<<"$usage_json")"

  credits_has="$(jq -r 'if .credits.has_credits == null then empty else .credits.has_credits end' <<<"$usage_json")"
  credits_unlimited_api="$(jq -r 'if .credits.unlimited == null then empty else .credits.unlimited end' <<<"$usage_json")"
  credits_balance_api="$(jq -r '.credits.balance // empty' <<<"$usage_json")"
  credits_balance_from_manual=false
  if [[ -z "$credits_balance_api" && -n "$credits_balance" ]]; then
    credits_balance_api="$credits_balance"
    credits_balance_from_manual=true
  fi
  credits_overage_reached="$(jq -r 'if .credits.overage_limit_reached == null then false else .credits.overage_limit_reached end' <<<"$usage_json")"
  spend_reached="$(jq -r 'if .spend_control.reached == null then false else .spend_control.reached end' <<<"$usage_json")"

  has_rate_limit=false
  if [[ "$primary_used" =~ ^[0-9]+([.][0-9]+)?$ || "$secondary_used" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    has_rate_limit=true
  fi

  effective_credits_has="$(credit_effective_has "$credits_has" "$credits_unlimited_api" "$credits_balance_api")"
  credits_limit_reached=false
  if truthy "$spend_reached" || truthy "$credits_overage_reached"; then
    credits_limit_reached=true
  fi
  credits_status_value="$(credit_status "$effective_credits_has" "$credits_unlimited_api" "$credits_balance_api" "$credits_limit_reached")"
  credits_compact="$(credit_compact_label "$effective_credits_has" "$credits_unlimited_api" "$credits_balance_api")"
  credits_display="$(credit_display_label "$effective_credits_has" "$credits_unlimited_api" "$credits_balance_api")"
  credits_basis="official Codex/ChatGPT credits balance"
  credits_is_estimate=false
  if [[ "$credits_balance_from_manual" == true ]]; then
    credits_basis="manual GPT credits balance; official API confirms Codex account"
    credits_is_estimate=true
    if ! truthy "$credits_unlimited_api"; then
      credits_compact="≈${credits_compact}"
      credits_display="≈${credits_display}"
    fi
  fi
  credits_color_value="$(credit_color "$credits_status_value" "$credits_unlimited_api" "$credits_balance_api")"
  if [[ "$credits_status_value" == "ok" ]]; then
    credits_message="${credits_display} (${credits_basis})"
  elif [[ "$credits_status_value" == "error" ]]; then
    credits_message="Codex credits spend control reached"
  else
    credits_message="Codex API missing credits balance"
  fi

  if [[ "$has_rate_limit" != "true" && "$credits_status_value" != "ok" && "$credits_status_value" != "error" ]]; then
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

  top_remaining="$primary_remaining"
  top_reset="$(number_or_null "$primary_reset")"
  if [[ "$top_remaining" == "null" && "$secondary_remaining" != "null" ]]; then
    top_remaining="$secondary_remaining"
    top_reset="$(number_or_null "$secondary_reset")"
  fi

  top_status="unknown"
  top_message="Codex usage API missing primary utilization"
  top_basis="official Codex/ChatGPT wham usage API"
  top_display_label=""
  top_display_color=""
  top_is_estimate=false
  if [[ "$top_remaining" != "null" ]]; then
    top_status="ok"
    top_message="${top_remaining}% left (official Codex/ChatGPT usage API)"
  elif [[ "$credits_status_value" == "ok" ]]; then
    top_status="ok"
    top_message="$credits_message"
    top_basis="$credits_basis"
    top_is_estimate="$credits_is_estimate"
    top_display_label="$credits_compact"
    top_display_color="$credits_color_value"
    top_reset="null"
  elif [[ "$credits_status_value" == "error" ]]; then
    top_status="error"
    top_message="$credits_message"
    top_basis="$credits_basis"
    top_is_estimate=false
    top_display_color="$credits_color_value"
    top_reset="null"
  fi

  credits_has_json="$effective_credits_has"
  credits_unlimited_json="$(bool_or_null "$credits_unlimited_api")"
  if [[ "$credits_unlimited_json" == "null" ]]; then
    credits_unlimited_json=false
  fi
  credits_balance_json="$(json_null_or_string "$credits_balance_api")"
  top_display_label_json="$(json_null_or_string "$top_display_label")"
  top_display_color_json="$(json_null_or_string "$top_display_color")"
  credits_display_json="$(json_null_or_string "$credits_display")"
  credits_compact_json="$(json_null_or_string "$credits_compact")"

  jq -n \
    --arg plan "$plan" \
    --argjson remaining "$top_remaining" \
    --argjson reset "$top_reset" \
    --arg status "$top_status" \
    --arg message "$top_message" \
    --arg basis "$top_basis" \
    --argjson top_is_estimate "$top_is_estimate" \
    --argjson display_label "$top_display_label_json" \
    --argjson display_color "$top_display_color_json" \
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
    --argjson credits_has "$credits_has_json" \
    --argjson credits_unlimited "$credits_unlimited_json" \
    --argjson credits_balance "$credits_balance_json" \
    --arg credits_status "$credits_status_value" \
    --arg credits_message "$credits_message" \
    --arg credits_basis "$credits_basis" \
    --arg credits_color "$credits_color_value" \
    --argjson credits_is_estimate "$credits_is_estimate" \
    --argjson credits_display_label "$credits_display_json" \
    --argjson credits_compact_label "$credits_compact_json" \
    '{
      enabled: true,
      remaining_percent: $remaining,
      reset_at: $reset,
      status: $status,
      message: $message,
      source: "codex_wham_usage_api",
      is_estimate: $top_is_estimate,
      basis: $basis,
      display_label: $display_label,
      display_color: $display_color,
      plan_type: $plan,
      credits: {
        has_credits: $credits_has,
        unlimited: $credits_unlimited,
        balance: $credits_balance,
        status: $credits_status,
        message: $credits_message,
        display_label: $credits_display_label,
        compact_label: $credits_compact_label,
        is_estimate: $credits_is_estimate,
        basis: (if $credits_status == "ok" then $credits_basis else null end)
      },
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
        },
        credits: {
          remaining_percent: null,
          reset_at: null,
          status: $credits_status,
          message: $credits_message,
          display_label: $credits_display_label,
          compact_label: $credits_compact_label,
          has_credits: $credits_has,
          unlimited: $credits_unlimited,
          balance: $credits_balance,
          is_estimate: $credits_is_estimate,
          basis: (if $credits_status == "ok" then $credits_basis else null end)
        }
      }
    }'
}

if [[ "$enabled" == "0" || "$enabled" == "false" || "$enabled" == "no" ]]; then
  jq -n '{enabled: false, remaining_percent: null, reset_at: null, status: "disabled", message: "disabled", source: "manual", windows: {"5h": {remaining_percent: null, reset_at: null, status: "disabled", message: "disabled"}, weekly: {remaining_percent: null, reset_at: null, status: "disabled", message: "disabled"}, credits: {remaining_percent: null, reset_at: null, status: "disabled", message: "disabled"}}}'
  exit 0
fi

if [[ -n "$status_override" && "$status_override" != "ok" ]]; then
  jq -n \
    --arg status "$status_override" \
    --arg message "${compact_message:-$status_override}" \
    '{enabled: true, remaining_percent: null, reset_at: null, status: $status, message: $message, source: "manual", windows: {"5h": {remaining_percent: null, reset_at: null, status: $status, message: $message}, weekly: {remaining_percent: null, reset_at: null, status: $status, message: $message}, credits: {remaining_percent: null, reset_at: null, status: $status, message: $message}}}'
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

manual_credits_has="$(credit_effective_has "$credits_has_credits" "$credits_unlimited" "$credits_balance")"
manual_credits_status="$(credit_status "$manual_credits_has" "$credits_unlimited" "$credits_balance" false)"
manual_credits_compact="$(credit_compact_label "$manual_credits_has" "$credits_unlimited" "$credits_balance")"
manual_credits_display="$(credit_display_label "$manual_credits_has" "$credits_unlimited" "$credits_balance")"
manual_credits_basis="manual user-provided GPT credits balance"
manual_credits_color="$(credit_color "$manual_credits_status" "$credits_unlimited" "$credits_balance")"
manual_credits_estimate=true
if [[ "$manual_credits_status" == "ok" ]]; then
  if ! truthy "$credits_unlimited"; then
    manual_credits_compact="≈${manual_credits_compact}"
    manual_credits_display="≈${manual_credits_display}"
  fi
  manual_credits_message="${credits_message_override:-${manual_credits_display} (${manual_credits_basis})}"
else
  manual_credits_message="configure GPT credits manual balance"
  manual_credits_estimate=false
fi

top_status="$(window_status "$top_remaining")"
top_message=""
top_basis="manual user-provided GPT Plus remaining value"
top_display_label=""
top_display_color=""
top_reset_at="$(json_null_or_string "$fiveh_reset_at")"
top_is_estimate=true
if [[ "$top_remaining" == "null" ]]; then
  if [[ "$manual_credits_status" == "ok" ]]; then
    top_status="ok"
    top_message="$manual_credits_message"
    top_basis="$manual_credits_basis"
    top_display_label="$manual_credits_compact"
    top_display_color="$manual_credits_color"
    top_reset_at="null"
  else
    top_status="unknown"
    top_message="Codex usage API unavailable; configure AI_USAGE_GPT_REMAINING_PERCENT, AI_USAGE_GPT_5H_REMAINING_PERCENT, or AI_USAGE_GPT_CREDITS_BALANCE"
    top_is_estimate=false
  fi
elif [[ "$top_status" == "ok" ]]; then
  top_message="${compact_message:-≈${top_remaining}% left (${top_basis})}"
else
  top_status="unknown"
  top_message="Codex usage API unavailable; configure AI_USAGE_GPT_REMAINING_PERCENT, AI_USAGE_GPT_5H_REMAINING_PERCENT, or AI_USAGE_GPT_CREDITS_BALANCE"
  top_is_estimate=false
fi

fiveh_json_remaining="$(percent_or_null "$fiveh_remaining")"
weekly_json_remaining="$(percent_or_null "$weekly_remaining")"
fiveh_status="$(window_status "$fiveh_json_remaining")"
weekly_status="$(window_status "$weekly_json_remaining")"
if [[ "$fiveh_json_remaining" == "null" ]]; then fiveh_status="unknown"; fi
if [[ "$weekly_json_remaining" == "null" ]]; then weekly_status="unknown"; fi

fiveh_message="$(if [[ "$fiveh_status" == ok ]]; then echo "${fiveh_message:-≈${fiveh_json_remaining}% left}"; else echo "configure GPT 5h manual remaining"; fi)"
weekly_message="$(if [[ "$weekly_status" == ok ]]; then echo "${weekly_message:-≈${weekly_json_remaining}% left}"; else echo "configure GPT weekly manual remaining"; fi)"

manual_credits_has_json="$manual_credits_has"
manual_credits_unlimited_json="$(bool_or_null "$credits_unlimited")"
if [[ "$manual_credits_unlimited_json" == "null" ]]; then
  manual_credits_unlimited_json=false
fi
manual_credits_balance_json="$(json_null_or_string "$credits_balance")"
top_display_label_json="$(json_null_or_string "$top_display_label")"
top_display_color_json="$(json_null_or_string "$top_display_color")"
manual_credits_display_json="$(json_null_or_string "$manual_credits_display")"
manual_credits_compact_json="$(json_null_or_string "$manual_credits_compact")"

jq -n \
  --argjson remaining "$top_remaining" \
  --argjson reset_at "$top_reset_at" \
  --arg status "$top_status" \
  --arg message "$top_message" \
  --arg basis "$top_basis" \
  --argjson top_is_estimate "$top_is_estimate" \
  --argjson display_label "$top_display_label_json" \
  --argjson display_color "$top_display_color_json" \
  --argjson fiveh_remaining "$fiveh_json_remaining" \
  --arg fiveh_status "$fiveh_status" \
  --arg fiveh_message "$fiveh_message" \
  --arg fiveh_basis "$top_basis" \
  --argjson fiveh_reset_at "$(json_null_or_string "$fiveh_reset_at")" \
  --argjson weekly_remaining "$weekly_json_remaining" \
  --arg weekly_status "$weekly_status" \
  --arg weekly_message "$weekly_message" \
  --arg weekly_basis "$top_basis" \
  --argjson weekly_reset_at "$(json_null_or_string "$weekly_reset_at")" \
  --argjson credits_has "$manual_credits_has_json" \
  --argjson credits_unlimited "$manual_credits_unlimited_json" \
  --argjson credits_balance "$manual_credits_balance_json" \
  --arg credits_status "$manual_credits_status" \
  --arg credits_message "$manual_credits_message" \
  --arg credits_basis "$manual_credits_basis" \
  --argjson credits_estimate "$manual_credits_estimate" \
  --argjson credits_display_label "$manual_credits_display_json" \
  --argjson credits_compact_label "$manual_credits_compact_json" \
  '{
    enabled: true,
    remaining_percent: $remaining,
    reset_at: $reset_at,
    status: $status,
    message: $message,
    source: "manual",
    is_estimate: $top_is_estimate,
    basis: (if $status == "ok" then $basis else null end),
    display_label: $display_label,
    display_color: $display_color,
    credits: {
      has_credits: $credits_has,
      unlimited: $credits_unlimited,
      balance: $credits_balance,
      status: $credits_status,
      message: $credits_message,
      display_label: $credits_display_label,
      compact_label: $credits_compact_label,
      is_estimate: $credits_estimate,
      basis: (if $credits_status == "ok" then $credits_basis else null end)
    },
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
      },
      credits: {
        remaining_percent: null,
        reset_at: null,
        status: $credits_status,
        message: $credits_message,
        display_label: $credits_display_label,
        compact_label: $credits_compact_label,
        has_credits: $credits_has,
        unlimited: $credits_unlimited,
        balance: $credits_balance,
        is_estimate: $credits_estimate,
        basis: (if $credits_status == "ok" then $credits_basis else null end)
      }
    }
  }'
