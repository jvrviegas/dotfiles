#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/items/ai_usage.lua"

# Detail rows use Claude as their default popup parent, so every provider click
# must toggle that populated shared popup instead of its own popup container.
grep -Fq 'parent = parent or claude_usage' "$SOURCE"
grep -Fq 'local drawing = claude_usage:query().popup.drawing' "$SOURCE"
grep -Fq 'claude_usage:set({ popup = { drawing = "toggle" } })' "$SOURCE"

grep -Fq 'claude_usage:subscribe("mouse.clicked", toggle_popup)' "$SOURCE"
grep -Fq 'gpt_usage:subscribe("mouse.clicked", toggle_popup)' "$SOURCE"
grep -Fq 'deepseek_usage:subscribe("mouse.clicked", toggle_popup)' "$SOURCE"

if rg -q 'toggle_popup\((claude_usage|gpt_usage|deepseek_usage)\)' "$SOURCE"; then
  echo "provider click still toggles an item-local popup" >&2
  exit 1
fi

echo "ai_usage_shared_popup_test: ok"
