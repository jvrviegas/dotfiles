#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sketchybar"
CACHE_FILE="$CACHE_DIR/ai_usage.json"
ENV_FILE="$CONFIG_DIR/ai_usage.env"
PROVIDER_DIR="$CONFIG_DIR/plugins/ai_usage_providers"
TTL_SECONDS="${AI_USAGE_TTL_SECONDS:-300}"
STALE_AFTER_SECONDS="${AI_USAGE_STALE_AFTER_SECONDS:-$((TTL_SECONDS * 3))}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

mkdir -p "$CACHE_DIR"

provider_prefix() {
  case "$1" in
    claude_code) echo "CLAUDE" ;;
    gpt_plus) echo "GPT" ;;
    *) echo "" ;;
  esac
}

status_json() {
  local enabled="$1" status="$2" message="$3" remaining="${4:-null}"

  jq -n \
    --argjson enabled "$enabled" \
    --arg status "$status" \
    --arg message "$message" \
    --argjson remaining "$remaining" \
    '{enabled: $enabled, remaining_percent: $remaining, reset_at: null, status: $status, message: $message}'
}

provider_json() {
  local name="$1" prefix enabled_var enabled script output message
  prefix="$(provider_prefix "$name")"
  enabled_var="AI_USAGE_${prefix}_ENABLED"
  enabled="${!enabled_var:-true}"

  if [[ "$enabled" == "0" || "$enabled" == "false" || "$enabled" == "no" ]]; then
    status_json false disabled disabled
    return 0
  fi

  script="$PROVIDER_DIR/$name.sh"
  if [[ ! -x "$script" ]]; then
    status_json true error "provider script missing: $name"
    return 0
  fi

  if output="$($script 2>&1)" && jq -e . >/dev/null 2>&1 <<<"$output"; then
    printf '%s\n' "$output"
    return 0
  fi

  message="provider failed: $name"
  if [[ -n "${output:-}" ]]; then
    message="$message ($(head -n 1 <<<"$output" | tr -d '\r'))"
  fi
  status_json true error "$message"
}

refresh_cache() {
  local claude gpt now old_claude_source new_claude_source
  claude="$(provider_json claude_code)"
  gpt="$(provider_json gpt_plus)"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Avoid visible cycling between official Claude usage and ccusage fallback when
  # the OAuth usage endpoint has a transient failure/rate limit. If we already
  # have official data, keep it until the official source refreshes again.
  if [[ -f "$CACHE_FILE" ]]; then
    old_claude_source="$(jq -r '.providers.claude.source // empty' "$CACHE_FILE" 2>/dev/null || true)"
    new_claude_source="$(jq -r '.source // empty' <<<"$claude" 2>/dev/null || true)"
    if [[ "$old_claude_source" == "claude_oauth_usage_api" && "$new_claude_source" != "claude_oauth_usage_api" && "${AI_USAGE_CLAUDE_ALLOW_FALLBACK_OVER_OFFICIAL:-false}" != "true" ]]; then
      claude="$(jq -c '.providers.claude + {message: ((.providers.claude.message // "") + " · using cached official value")}' "$CACHE_FILE")"
    fi
  fi

  jq -n \
    --arg updated_at "$now" \
    --argjson claude "$claude" \
    --argjson gpt "$gpt" \
    '{providers: {claude: ($claude + {label: "C"}), gpt: ($gpt + {label: "G"})}, updated_at: $updated_at}' \
    > "$CACHE_FILE.tmp"
  mv "$CACHE_FILE.tmp" "$CACHE_FILE"
}

cache_age() {
  if [[ ! -f "$CACHE_FILE" ]]; then
    echo 999999
    return
  fi

  local now modified
  now="$(date +%s)"
  modified="$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)"
  echo $((now - modified))
}

ensure_cache() {
  local age
  age="$(cache_age)"
  if (( age > TTL_SECONDS )); then
    refresh_cache || true
  fi

  if [[ ! -f "$CACHE_FILE" ]]; then
    refresh_cache || true
  fi
}

provider_display() {
  local data="$1" key="$2" remaining status estimate prefix
  remaining="$(jq -r ".providers.$key.remaining_percent // \"?\"" <<<"$data" 2>/dev/null || echo '?')"
  status="$(jq -r ".providers.$key.status // \"unknown\"" <<<"$data" 2>/dev/null || echo 'unknown')"
  estimate="$(jq -r ".providers.$key.is_estimate // false" <<<"$data" 2>/dev/null || echo false)"
  prefix=""
  if [[ "$estimate" == "true" ]]; then
    prefix="≈"
  fi

  case "$status" in
    disabled) echo "off" ;;
    error) echo "!" ;;
    *)
      if [[ "$remaining" == "?" ]]; then
        echo "?"
      else
        echo "${prefix}${remaining}%"
      fi
      ;;
  esac
}

render() {
  ensure_cache

  local data age stale claude_display gpt_display label details min_remaining color has_error
  data="$(cat "$CACHE_FILE" 2>/dev/null || echo '{}')"
  age="$(cache_age)"
  stale=false
  if (( age > STALE_AFTER_SECONDS )); then
    stale=true
  fi

  claude_display="$(provider_display "$data" claude)"
  gpt_display="$(provider_display "$data" gpt)"
  label="C:${claude_display} G:${gpt_display}"

  details="Claude: $(jq -r '.providers.claude.message // "unknown"' <<<"$data" 2>/dev/null || echo 'unknown') · GPT: $(jq -r '.providers.gpt.message // "unknown"' <<<"$data" 2>/dev/null || echo 'unknown')"
  if [[ "$stale" == true ]]; then
    label="~ ${label}"
    details="stale cache · ${details}"
  fi

  color="grey"
  has_error="$(jq -r '[.providers[].status == "error"] | any' <<<"$data" 2>/dev/null || echo false)"
  min_remaining="$(jq -r '[.providers[] | select(.status == "ok") | .remaining_percent | select(type == "number")] | if length == 0 then empty else min end' <<<"$data" 2>/dev/null || true)"

  if [[ "$stale" == true ]]; then
    color="grey"
  elif [[ "$has_error" == "true" ]]; then
    color="red"
  elif [[ -n "$min_remaining" ]]; then
    if (( min_remaining < 20 )); then
      color="red"
    elif (( min_remaining <= 50 )); then
      color="yellow"
    else
      color="green"
    fi
  fi

  printf 'LABEL=%s\nCOLOR=%s\nDETAILS=%s\nSTATUS=%s\n' "$label" "$color" "$details" "$([[ "$stale" == true ]] && echo stale || echo ok)"
}

format_time() {
  local value="$1"
  if [[ -z "$value" || "$value" == "null" ]]; then
    return 0
  fi

  local formatted
  if command -v python3 >/dev/null 2>&1; then
    if formatted="$(python3 - "$value" 2>/dev/null <<'PY'
import datetime as dt
import sys

value = sys.argv[1]
try:
    if value.isdigit():
        d = dt.datetime.fromtimestamp(int(value)).astimezone()
    else:
        normalized = value.replace('Z', '+00:00')
        d = dt.datetime.fromisoformat(normalized)
        if d.tzinfo is None:
            d = d.replace(tzinfo=dt.timezone.utc)
        d = d.astimezone()
    now = dt.datetime.now().astimezone()
    if d.date() == now.date():
        text = d.strftime('%I:%M %p').lstrip('0')
    else:
        text = d.strftime('%a %I:%M %p').replace(' 0', ' ')
    print(text, end='')
except Exception:
    print(value, end='')
PY
)"; then
      printf '%s' "$formatted"
      return 0
    fi
  fi

  if command -v node >/dev/null 2>&1; then
    if formatted="$(node -e '
      const value = process.argv[1];
      const numeric = /^\d+$/.test(value) ? Number(value) : NaN;
      const d = Number.isFinite(numeric) ? new Date(numeric * 1000) : new Date(value);
      if (Number.isNaN(d.getTime())) {
        process.stdout.write(value);
      } else {
        const now = new Date();
        const sameDay = d.toDateString() === now.toDateString();
        const opts = sameDay
          ? { hour: "2-digit", minute: "2-digit" }
          : { weekday: "short", hour: "2-digit", minute: "2-digit" };
        process.stdout.write(new Intl.DateTimeFormat(undefined, opts).format(d));
      }
    ' "$value" 2>/dev/null)"; then
      printf '%s' "$formatted"
      return 0
    fi
  fi

  printf '%s' "$value"
}

window_display() {
  local data="$1" provider="$2" window="$3" status remaining reset message estimate value reset_label
  status="$(jq -r ".providers.$provider.windows[\"$window\"].status // .providers.$provider.status // \"unknown\"" <<<"$data" 2>/dev/null || echo unknown)"
  remaining="$(jq -r ".providers.$provider.windows[\"$window\"].remaining_percent // \"?\"" <<<"$data" 2>/dev/null || echo '?')"
  reset="$(jq -r ".providers.$provider.windows[\"$window\"].reset_at // empty" <<<"$data" 2>/dev/null || true)"
  message="$(jq -r ".providers.$provider.windows[\"$window\"].message // .providers.$provider.message // \"unknown\"" <<<"$data" 2>/dev/null || echo unknown)"
  estimate="$(jq -r ".providers.$provider.windows[\"$window\"].is_estimate // .providers.$provider.is_estimate // false" <<<"$data" 2>/dev/null || echo false)"

  case "$status" in
    ok)
      if [[ "$estimate" == "true" ]]; then
        value="≈${remaining}% left"
      else
        value="${remaining}% left"
      fi
      ;;
    disabled) value="off" ;;
    error) value="! ${message}" ;;
    *) value="? ${message}" ;;
  esac

  if [[ -n "$reset" && "$reset" != "null" ]]; then
    reset_label="$(format_time "$reset")"
    value="$value · resets $reset_label"
  fi

  printf '%s' "$value"
}

doctor() {
  ensure_cache

  local data
  data="$(cat "$CACHE_FILE" 2>/dev/null || echo '{}')"

  jq -r '
    "AI Usage diagnostics",
    "cache: " + "'"$CACHE_FILE"'",
    "updated_at: " + (.updated_at // "unknown"),
    "",
    (.providers | to_entries[] |
      (.key + ": status=" + (.value.status // "unknown")
        + " source=" + (.value.source // "unknown")
        + " estimate=" + ((.value.is_estimate // false) | tostring)
        + " basis=" + (.value.basis // "n/a")
        + " message=" + (.value.message // "")))
  ' <<<"$data"
}

popup() {
  ensure_cache

  local data updated_at
  data="$(cat "$CACHE_FILE" 2>/dev/null || echo '{}')"
  updated_at="$(jq -r '.updated_at // "unknown"' <<<"$data" 2>/dev/null || echo unknown)"
  if [[ "$updated_at" != "unknown" ]]; then
    updated_at="$(format_time "$updated_at")"
  fi

  printf 'CLAUDE_5H=%s\n' "$(window_display "$data" claude 5h)"
  printf 'CLAUDE_WEEKLY=%s\n' "$(window_display "$data" claude weekly)"
  printf 'GPT_5H=%s\n' "$(window_display "$data" gpt 5h)"
  printf 'GPT_WEEKLY=%s\n' "$(window_display "$data" gpt weekly)"
  printf 'UPDATED_AT=%s\n' "$updated_at"
}

case "${1:-render}" in
  render) render ;;
  popup) popup ;;
  refresh) refresh_cache && render ;;
  refresh-popup) refresh_cache && popup ;;
  doctor) doctor ;;
  cache) ensure_cache; cat "$CACHE_FILE" ;;
  *) echo "usage: $0 [render|popup|refresh|refresh-popup|doctor|cache]" >&2; exit 2 ;;
esac
