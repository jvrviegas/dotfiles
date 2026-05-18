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
      "is_estimate": true,
      "basis": "ccusage used tokens / configured local tokens limit",
      "message": "≈70% left",
      "source": "ccusage",
      "windows": {
        "5h": { "status": "ok", "remaining_percent": 70, "is_estimate": true, "reset_at": null, "message": "≈70% left" },
        "weekly": { "status": "ok", "remaining_percent": 80, "is_estimate": true, "reset_at": null, "message": "≈80% left" }
      }
    },
    "gpt": {
      "status": "ok",
      "remaining_percent": 40,
      "is_estimate": true,
      "basis": "manual user-provided GPT Plus remaining value",
      "message": "≈40% left",
      "source": "manual",
      "windows": {
        "5h": { "status": "ok", "remaining_percent": 40, "is_estimate": true, "reset_at": null, "message": "≈40% left" },
        "weekly": { "status": "ok", "remaining_percent": 85, "is_estimate": true, "reset_at": null, "message": "≈85% left" }
      }
    }
  },
  "updated_at": "2026-05-12T12:00:00Z"
}
JSON

render_output="$(CONFIG_DIR="$TMP_DIR/missing" XDG_CACHE_HOME="$TMP_DIR" AI_USAGE_TTL_SECONDS=9999999999 "$ROOT_DIR/plugins/ai_usage.sh" render)"
grep -q '^LABEL=C:≈70% G:≈40%' <<<"$render_output"

popup_output="$(CONFIG_DIR="$TMP_DIR/missing" XDG_CACHE_HOME="$TMP_DIR" AI_USAGE_TTL_SECONDS=9999999999 "$ROOT_DIR/plugins/ai_usage.sh" popup)"
grep -q '^CLAUDE_5H=≈70% left$' <<<"$popup_output"
grep -q '^GPT_WEEKLY=≈85% left$' <<<"$popup_output"

doctor_output="$(CONFIG_DIR="$TMP_DIR/missing" XDG_CACHE_HOME="$TMP_DIR" AI_USAGE_TTL_SECONDS=9999999999 "$ROOT_DIR/plugins/ai_usage.sh" doctor)"
grep -q 'claude: status=ok source=ccusage estimate=true basis=ccusage used tokens / configured local tokens limit' <<<"$doctor_output"
grep -q 'gpt: status=ok source=manual estimate=true basis=manual user-provided GPT Plus remaining value' <<<"$doctor_output"

echo "ai_usage_estimate_render_test: ok"
