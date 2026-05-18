#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/sketchybar"
cat > "$TMP_DIR/sketchybar/ai_usage.json" <<'JSON'
{
  "providers": {
    "claude": {
      "status": "ok",
      "remaining_percent": 70,
      "message": "70% left",
      "windows": {
        "5h": { "status": "ok", "remaining_percent": 70, "reset_at": "2026-05-12T18:00:00Z", "message": "70% left" },
        "weekly": { "status": "ok", "remaining_percent": 80, "reset_at": "2026-05-17T00:00:00Z", "message": "80% left" }
      }
    },
    "gpt": {
      "status": "unknown",
      "remaining_percent": null,
      "message": "manual setup required",
      "windows": {
        "5h": { "status": "unknown", "remaining_percent": null, "reset_at": null, "message": "configure GPT 5h manual remaining" },
        "weekly": { "status": "ok", "remaining_percent": 85, "reset_at": 1779135357, "message": "85% left" }
      }
    }
  },
  "updated_at": "2026-05-12T12:00:00Z"
}
JSON

output="$(CONFIG_DIR="$TMP_DIR/missing" XDG_CACHE_HOME="$TMP_DIR" AI_USAGE_TTL_SECONDS=9999999999 "$ROOT_DIR/plugins/ai_usage.sh" popup)"

grep -q '^CLAUDE_5H=70% left · resets ' <<<"$output"
grep -q '^CLAUDE_WEEKLY=80% left · resets ' <<<"$output"
grep -q '^GPT_5H=? configure GPT 5h manual remaining$' <<<"$output"
grep -q '^GPT_WEEKLY=85% left · resets ' <<<"$output"
grep -q '^UPDATED_AT=' <<<"$output"

if grep -q '2026-05-12T18:00:00Z\|1779135357' <<<"$output"; then
  echo "raw ISO timestamp was not formatted" >&2
  exit 1
fi

echo "ai_usage_popup_test: ok"
