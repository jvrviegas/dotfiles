#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin"
cat > "$TMP_DIR/bin/ccusage" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  blocks) echo '{"blocks":[{"startTime":"2026-05-12T06:00:00.000Z","endTime":"2026-05-12T11:00:00.000Z","isActive":true,"totalTokens":999,"costUSD":1}]}' ;;
  weekly) echo '{"weekly":[{"week":"2026-05-10","totalTokens":999,"totalCost":1}]}' ;;
  *) exit 2 ;;
esac
MOCK
chmod +x "$TMP_DIR/bin/ccusage"

output="$(PATH="$TMP_DIR/bin:$PATH" \
  AI_USAGE_CLAUDE_API_ENABLED=false \
  AI_USAGE_CLAUDE_5H_USED_PERCENT=13 \
  AI_USAGE_CLAUDE_5H_RESET_AT="in 11 min" \
  AI_USAGE_CLAUDE_WEEKLY_USED_PERCENT=10 \
  AI_USAGE_CLAUDE_WEEKLY_RESET_AT="Thu 9:00 AM" \
  "$ROOT_DIR/plugins/ai_usage_providers/claude_code.sh")"

jq -e '
  .remaining_percent == 87 and
  .basis == "manual Claude plan limits UI used percent" and
  .windows["5h"].remaining_percent == 87 and
  .windows["5h"].reset_at == "in 11 min" and
  .windows["5h"].basis == "manual Claude plan limits UI used percent" and
  .windows.weekly.remaining_percent == 90 and
  .windows.weekly.reset_at == "Thu 9:00 AM" and
  .windows.weekly.basis == "manual Claude plan limits UI used percent"
' <<<"$output" >/dev/null

echo "ai_usage_claude_ui_override_test: ok"
