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
      "is_estimate": false,
      "message": "70% left",
      "windows": {
        "5h": { "status": "ok", "remaining_percent": 70, "reset_at": null, "message": "70% left" },
        "weekly": { "status": "ok", "remaining_percent": 80, "reset_at": null, "message": "80% left" }
      }
    },
    "gpt": {
      "status": "ok",
      "remaining_percent": null,
      "display_label": "82.4cr",
      "display_color": "green",
      "is_estimate": false,
      "message": "82.4 credits (official Codex/ChatGPT credits balance)",
      "source": "codex_wham_usage_api",
      "windows": {
        "5h": { "status": "unknown", "remaining_percent": null, "reset_at": null, "message": "Codex API missing 5-hour window usage" },
        "weekly": { "status": "unknown", "remaining_percent": null, "reset_at": null, "message": "Codex API missing weekly window usage" },
        "credits": { "status": "ok", "display_label": "82.4 credits", "balance": "82.4", "message": "82.4 credits (official Codex/ChatGPT credits balance)" }
      }
    }
  },
  "updated_at": "2026-05-12T12:00:00Z"
}
JSON

render_output="$(CONFIG_DIR="$TMP_DIR/missing" XDG_CACHE_HOME="$TMP_DIR" AI_USAGE_TTL_SECONDS=9999999999 "$ROOT_DIR/plugins/ai_usage.sh" render)"
grep -q '^LABEL=C:70% G:82.4cr' <<<"$render_output"
grep -q '^GPT_LABEL=82.4cr$' <<<"$render_output"
grep -q '^GPT_COLOR=green$' <<<"$render_output"

popup_output="$(CONFIG_DIR="$TMP_DIR/missing" XDG_CACHE_HOME="$TMP_DIR" AI_USAGE_TTL_SECONDS=9999999999 "$ROOT_DIR/plugins/ai_usage.sh" popup)"
grep -q '^GPT_5H=? Codex API missing 5-hour window usage$' <<<"$popup_output"
grep -q '^GPT_WEEKLY=? Codex API missing weekly window usage$' <<<"$popup_output"
grep -q '^GPT_CREDITS=82.4 credits$' <<<"$popup_output"

echo "ai_usage_gpt_credits_render_test: ok"
