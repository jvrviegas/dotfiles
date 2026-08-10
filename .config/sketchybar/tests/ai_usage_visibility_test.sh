#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT_DIR/plugins/ai_usage_visibility.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

EMPTY_CONFIG="$TMP_DIR/empty-config"
mkdir -p "$EMPTY_CONFIG"

initial="$(CONFIG_DIR="$EMPTY_CONFIG" "$HELPER" get)"
grep -q '^CLAUDE_VISIBLE=true$' <<<"$initial"
grep -q '^GPT_VISIBLE=true$' <<<"$initial"
grep -q '^DEEPSEEK_VISIBLE=true$' <<<"$initial"
[[ ! -e "$EMPTY_CONFIG/ai_usage.env" ]]

CONFIG_DIR="$EMPTY_CONFIG" "$HELPER" toggle gpt >/dev/null
grep -q '^AI_USAGE_GPT_VISIBLE=false$' "$EMPTY_CONFIG/ai_usage.env"
grep -q '^GPT_VISIBLE=false$' <<<"$(CONFIG_DIR="$EMPTY_CONFIG" "$HELPER" get)"
[[ -z "$(find "$EMPTY_CONFIG" -maxdepth 1 -name 'ai_usage.env.tmp.*' -print -quit)" ]]

CONFIG_DIR_TEST="$TMP_DIR/config"
mkdir -p "$CONFIG_DIR_TEST"
cat > "$CONFIG_DIR_TEST/ai_usage.env" <<'ENV'
# Keep this comment.
AI_USAGE_CLAUDE_VISIBLE=maybe # Keep this inline comment.
AI_USAGE_GPT_VISIBLE=false
OTHER_SETTING=preserve-me

# AI_USAGE_DEEPSEEK_VISIBLE=false is intentionally commented out.
ENV

invalid_state="$(CONFIG_DIR="$CONFIG_DIR_TEST" "$HELPER" get)"
grep -q '^CLAUDE_VISIBLE=true$' <<<"$invalid_state"
grep -q '^GPT_VISIBLE=false$' <<<"$invalid_state"
grep -q '^DEEPSEEK_VISIBLE=true$' <<<"$invalid_state"

CONFIG_DIR="$CONFIG_DIR_TEST" "$HELPER" toggle claude >/dev/null
grep -q '^AI_USAGE_CLAUDE_VISIBLE=false # Keep this inline comment\.$' "$CONFIG_DIR_TEST/ai_usage.env"
grep -q '^AI_USAGE_GPT_VISIBLE=false$' "$CONFIG_DIR_TEST/ai_usage.env"
grep -q '^OTHER_SETTING=preserve-me$' "$CONFIG_DIR_TEST/ai_usage.env"
grep -q '^# Keep this comment\.$' "$CONFIG_DIR_TEST/ai_usage.env"
grep -q '^# AI_USAGE_DEEPSEEK_VISIBLE=false is intentionally commented out\.$' "$CONFIG_DIR_TEST/ai_usage.env"

CONFIG_DIR="$CONFIG_DIR_TEST" "$HELPER" toggle gpt >/dev/null
state="$(CONFIG_DIR="$CONFIG_DIR_TEST" "$HELPER" get)"
grep -q '^CLAUDE_VISIBLE=false$' <<<"$state"
grep -q '^GPT_VISIBLE=true$' <<<"$state"
grep -q '^DEEPSEEK_VISIBLE=true$' <<<"$state"

CONFIG_DIR="$CONFIG_DIR_TEST" "$HELPER" toggle deepseek >/dev/null
grep -q '^DEEPSEEK_VISIBLE=false$' <<<"$(CONFIG_DIR="$CONFIG_DIR_TEST" "$HELPER" get)"
[[ -z "$(find "$CONFIG_DIR_TEST" -maxdepth 1 -name 'ai_usage.env.tmp.*' -print -quit)" ]]

echo "ai_usage_visibility_test: ok"
