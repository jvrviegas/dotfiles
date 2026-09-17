#!/usr/bin/env bash
set -euo pipefail

# DeepSeek platform usage provider.
#
# Data source: DeepSeek user balance API
#   GET https://api.deepseek.com/user/balance
#   Returns balance info with currency, total_balance, etc.
#
# Config in ~/.config/sketchybar/ai_usage.env:
#   AI_USAGE_DEEPSEEK_ENABLED=false       # disable entirely
#   AI_USAGE_DEEPSEEK_API_KEY=sk-...      # API key (defaults to $DEEPSEEK_API_KEY)
#   AI_USAGE_DEEPSEEK_STATUS=error        # force error status for testing
#   AI_USAGE_DEEPSEEK_MANUAL_BALANCE=10.00 # manual fallback balance
#   AI_USAGE_DEEPSEEK_MANUAL_CURRENCY=USD  # manual fallback currency

enabled="${AI_USAGE_DEEPSEEK_ENABLED:-true}"
api_key="${AI_USAGE_DEEPSEEK_API_KEY:-${DEEPSEEK_API_KEY:-}}"
status_override="${AI_USAGE_DEEPSEEK_STATUS:-}"
manual_balance="${AI_USAGE_DEEPSEEK_MANUAL_BALANCE:-}"
manual_currency="${AI_USAGE_DEEPSEEK_MANUAL_CURRENCY:-USD}"

lower_value() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

truthy() {
  local value
  value="$(lower_value "$1")"
  [[ "$value" == "true" || "$value" == "1" || "$value" == "yes" || "$value" == "y" || "$value" == "on" ]]
}

format_balance() {
  local balance="$1"
  if [[ ! "$balance" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf '%s' "$balance"
    return 0
  fi

  awk -v balance="$balance" 'BEGIN {
    if (balance >= 100) {
      printf "%.0f", balance
    } else if (balance >= 10) {
      printf "%.1f", balance
    } else {
      printf "%.2f", balance
    }
  }' | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'
}

currency_symbol() {
  case "$1" in
    USD) printf '$' ;;
    CNY) printf '¥' ;;
    *) printf '%s' "$1" ;;
  esac
}

fetch_balance() {
  if [[ -z "$api_key" ]]; then
    return 1
  fi

  if [[ ! -x "$(command -v curl 2>/dev/null)" ]]; then
    return 1
  fi

  curl -fsS \
    --connect-timeout 5 \
    --max-time 10 \
    -H "Authorization: Bearer $api_key" \
    -H "Accept: application/json" \
    'https://api.deepseek.com/user/balance' 2>/dev/null
}

emit_api_balance() {
  local balance_json="$1"
  local is_available balance_infos total_balance currency granted topped_up
  local symbol display_label compact_label status color message

  is_available="$(jq -r '.is_available // false' <<<"$balance_json")"
  balance_infos="$(jq -r '.balance_infos // []' <<<"$balance_json")"
  total_balance="$(jq -r 'first(.balance_infos[]?.total_balance) // empty' <<<"$balance_json")"
  currency="$(jq -r 'first(.balance_infos[]?.currency) // "USD"' <<<"$balance_json")"
  granted="$(jq -r 'first(.balance_infos[]?.granted_balance) // "0"' <<<"$balance_json")"
  topped_up="$(jq -r 'first(.balance_infos[]?.topped_up_balance) // "0"' <<<"$balance_json")"

  symbol="$(currency_symbol "$currency")"
  display_label="$(format_balance "$total_balance")"
  compact_label="${symbol}${display_label}"

  if truthy "$is_available"; then
    status="ok"
    color="green"
    message="${compact_label} available (DeepSeek API)"
  else
    # Balance exists but is_available is false (balance too low)
    status="ok"
    color="yellow"
    message="${compact_label} balance low (DeepSeek API)"
    if [[ "$total_balance" == "0" || "$total_balance" == "0.00" ]]; then
      color="red"
      status="ok"
      message="${compact_label} depleted (DeepSeek API)"
    fi
  fi

  jq -n \
    --argjson enabled true \
    --arg status "$status" \
    --arg message "$message" \
    --arg source "deepseek_api" \
    --argjson is_estimate false \
    --arg basis "official DeepSeek balance API" \
    --arg display_label "$compact_label" \
    --arg display_color "$color" \
    --arg currency "$currency" \
    --arg total_balance "$total_balance" \
    --arg granted_balance "$granted" \
    --arg topped_up_balance "$topped_up" \
    --argjson is_available "$is_available" \
    '{
      enabled: $enabled,
      remaining_percent: null,
      reset_at: null,
      status: $status,
      message: $message,
      source: $source,
      is_estimate: $is_estimate,
      basis: $basis,
      display_label: $display_label,
      display_color: $display_color,
      balance: {
        currency: $currency,
        total: $total_balance,
        granted: $granted_balance,
        topped_up: $topped_up_balance,
        is_available: $is_available
      },
      windows: {}
    }'
}

# --- Disabled ---
if [[ "$enabled" == "0" || "$enabled" == "false" || "$enabled" == "no" ]]; then
  jq -n '{enabled: false, remaining_percent: null, reset_at: null, status: "disabled", message: "disabled", source: "manual", windows: {}}'
  exit 0
fi

# --- Status override ---
if [[ -n "$status_override" && "$status_override" != "ok" ]]; then
  jq -n \
    --arg status "$status_override" \
    --arg message "$status_override" \
    '{enabled: true, remaining_percent: null, reset_at: null, status: $status, message: $message, source: "manual", windows: {}}'
  exit 0
fi

# --- API fetch ---
if [[ -n "$api_key" ]]; then
  balance_json="$(fetch_balance || true)"
  if jq -e . >/dev/null 2>&1 <<<"$balance_json" && \
     jq -e '.balance_infos and (.balance_infos | length > 0)' >/dev/null 2>&1 <<<"$balance_json"; then
    emit_api_balance "$balance_json"
    exit 0
  fi

  # API call failed
  jq -n \
    --arg message "DeepSeek API unreachable (key set but request failed)" \
    '{enabled: true, remaining_percent: null, reset_at: null, status: "error", message: $message, source: "deepseek_api", windows: {}}'
  exit 0
fi

# --- Manual fallback ---
if [[ -n "$manual_balance" && "$manual_balance" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  symbol="$(currency_symbol "$manual_currency")"
  display="$(format_balance "$manual_balance")"
  compact="${symbol}${display}"

  jq -n \
    --argjson enabled true \
    --arg status "ok" \
    --arg message "≈${compact} (manual balance)" \
    --arg source "manual" \
    --argjson is_estimate true \
    --arg basis "manual user-provided DeepSeek balance" \
    --arg display_label "$compact" \
    --arg display_color "green" \
    --arg currency "$manual_currency" \
    --arg total_balance "$manual_balance" \
    --arg granted_balance "0" \
    --arg topped_up_balance "$manual_balance" \
    --argjson is_available true \
    '{
      enabled: $enabled,
      remaining_percent: null,
      reset_at: null,
      status: $status,
      message: $message,
      source: $source,
      is_estimate: $is_estimate,
      basis: $basis,
      display_label: $display_label,
      display_color: $display_color,
      balance: {
        currency: $currency,
        total: $total_balance,
        granted: $granted_balance,
        topped_up: $topped_up_balance,
        is_available: $is_available
      },
      windows: {}
    }'
  exit 0
fi

# --- No API key, no manual fallback ---
jq -n \
  '{enabled: true, remaining_percent: null, reset_at: null, status: "error", message: "set DEEPSEEK_API_KEY or AI_USAGE_DEEPSEEK_API_KEY", source: "manual", windows: {}}'
