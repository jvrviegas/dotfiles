#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
ENV_FILE="$CONFIG_DIR/ai_usage.env"
TEMP_FILE=""

cleanup() {
  if [[ -n "$TEMP_FILE" ]]; then
    rm -f "$TEMP_FILE"
  fi
}
trap cleanup EXIT

provider_prefix() {
  case "$1" in
    claude|CLAUDE|claude_code) printf 'CLAUDE' ;;
    gpt|GPT|gpt_plus|codex) printf 'GPT' ;;
    deepseek|DEEPSEEK) printf 'DEEPSEEK' ;;
    *)
      echo "unknown provider: $1" >&2
      return 2
      ;;
  esac
}

normalize_visibility() {
  local value="${1:-}" normalized

  value="$(printf '%s' "$value" | sed -E \
    's/[[:space:]]+#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//')"

  if [[ "${#value}" -ge 2 && "${value:0:1}" == '"' && "${value:${#value}-1:1}" == '"' ]]; then
    value="${value:1:${#value}-2}"
  elif [[ "${#value}" -ge 2 && "${value:0:1}" == "'" && "${value:${#value}-1:1}" == "'" ]]; then
    value="${value:1:${#value}-2}"
  fi

  normalized="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  case "$normalized" in
    true) printf 'true' ;;
    false) printf 'false' ;;
    *) printf 'true' ;;
  esac
}

read_visibility() {
  local prefix="$1" key line value="" assignment_regex
  key="AI_USAGE_${prefix}_VISIBLE"

  if [[ -f "$ENV_FILE" ]]; then
    assignment_regex="^[[:space:]]*(export[[:space:]]+)?${key}[[:space:]]*=(.*)$"
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" =~ $assignment_regex ]]; then
        # The last assignment wins, matching normal shell configuration behavior.
        value="${BASH_REMATCH[2]}"
      fi
    done < "$ENV_FILE"
  fi

  normalize_visibility "$value"
}

emit_state() {
  printf 'CLAUDE_VISIBLE=%s\n' "$(read_visibility CLAUDE)"
  printf 'GPT_VISIBLE=%s\n' "$(read_visibility GPT)"
  printf 'DEEPSEEK_VISIBLE=%s\n' "$(read_visibility DEEPSEEK)"
}

write_visibility() {
  local key="$1" value="$2" mode="" tmp

  mkdir -p "$CONFIG_DIR"
  tmp="$(mktemp "$ENV_FILE.tmp.XXXXXX")"
  TEMP_FILE="$tmp"

  if [[ -f "$ENV_FILE" ]]; then
    awk -v key="$key" -v value="$value" '
      BEGIN {
        assignment = "^[[:space:]]*(export[[:space:]]+)?" key "[[:space:]]*=[[:space:]]*"
        found = 0
      }
      {
        if ($0 ~ assignment) {
          match($0, assignment)
          prefix = substr($0, 1, RLENGTH)
          rest = substr($0, RLENGTH + 1)
          suffix = ""
          if (match(rest, /[[:space:]]+#.*/)) {
            suffix = substr(rest, RSTART)
          }
          print prefix value suffix
          found = 1
        } else {
          print $0
        }
      }
      END {
        if (!found) print key "=" value
      }
    ' "$ENV_FILE" > "$tmp"
  else
    printf '%s=%s\n' "$key" "$value" > "$tmp"
  fi

  # Keep existing permissions when replacing a config file containing secrets.
  if [[ -e "$ENV_FILE" ]]; then
    if ! mode="$(stat -f '%Lp' "$ENV_FILE" 2>/dev/null)"; then
      mode="$(stat -c '%a' "$ENV_FILE" 2>/dev/null || true)"
    fi
    if [[ -n "$mode" ]]; then
      chmod "$mode" "$tmp"
    fi
  fi

  mv -f "$tmp" "$ENV_FILE"
  TEMP_FILE=""
}

usage() {
  echo "usage: $0 [get [provider]|toggle provider]" >&2
  exit 2
}

command="${1:-get}"
case "$command" in
  get)
    if [[ "$#" -eq 1 ]]; then
      emit_state
    elif [[ "$#" -eq 2 ]]; then
      prefix="$(provider_prefix "$2")"
      printf '%s_VISIBLE=%s\n' "$prefix" "$(read_visibility "$prefix")"
    else
      usage
    fi
    ;;
  toggle)
    if [[ "$#" -ne 2 ]]; then
      usage
    fi

    prefix="$(provider_prefix "$2")"
    current="$(read_visibility "$prefix")"
    if [[ "$current" == 'true' ]]; then
      next='false'
    else
      next='true'
    fi
    write_visibility "AI_USAGE_${prefix}_VISIBLE" "$next"
    emit_state
    ;;
  *)
    usage
    ;;
esac
