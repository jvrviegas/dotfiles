#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

output="$(
  AI_USAGE_GPT_API_ENABLED=false \
  AI_USAGE_GPT_5H_REMAINING_PERCENT=40 \
  AI_USAGE_GPT_5H_RESET_AT="2026-05-12T18:00:00Z" \
  AI_USAGE_GPT_WEEKLY_REMAINING_PERCENT=85 \
  AI_USAGE_GPT_WEEKLY_RESET_AT="2026-05-17T00:00:00Z" \
  "$ROOT_DIR/plugins/ai_usage_providers/gpt_plus.sh"
)"

jq -e '
  .source == "manual" and
  .status == "ok" and
  .remaining_percent == 40 and
  .is_estimate == true and
  .basis == "manual user-provided GPT Plus remaining value" and
  .reset_at == "2026-05-12T18:00:00Z" and
  .windows["5h"].remaining_percent == 40 and
  .windows["5h"].is_estimate == true and
  .windows.weekly.remaining_percent == 85 and
  .windows.weekly.reset_at == "2026-05-17T00:00:00Z"
' <<<"$output" >/dev/null

unknown_output="$(AI_USAGE_GPT_API_ENABLED=false $ROOT_DIR/plugins/ai_usage_providers/gpt_plus.sh)"
jq -e '
  .source == "manual" and
  .status == "unknown" and
  .remaining_percent == null and
  .windows["5h"].status == "unknown" and
  .windows.weekly.status == "unknown"
' <<<"$unknown_output" >/dev/null

disabled_output="$(AI_USAGE_GPT_ENABLED=false "$ROOT_DIR/plugins/ai_usage_providers/gpt_plus.sh")"
jq -e '
  .enabled == false and
  .status == "disabled" and
  .windows["5h"].status == "disabled" and
  .windows.weekly.status == "disabled"
' <<<"$disabled_output" >/dev/null

echo "ai_usage_gpt_provider_test: ok"
