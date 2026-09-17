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
  blocks)
    cat <<'JSON'
{
  "blocks": [
    {
      "id": "2026-05-12T06:00:00.000Z",
      "startTime": "2026-05-12T06:00:00.000Z",
      "endTime": "2026-05-12T11:00:00.000Z",
      "isActive": true,
      "totalTokens": 250,
      "costUSD": 12.5
    }
  ]
}
JSON
    ;;
  weekly)
    cat <<'JSON'
{
  "weekly": [
    {
      "week": "2026-05-10",
      "totalTokens": 1000,
      "totalCost": 20
    }
  ]
}
JSON
    ;;
  *) exit 2 ;;
esac
MOCK
chmod +x "$TMP_DIR/bin/ccusage"

output="$(PATH="$TMP_DIR/bin:$PATH" \
  AI_USAGE_CLAUDE_API_ENABLED=false \
  AI_USAGE_CLAUDE_5H_TOKEN_LIMIT=1000 \
  AI_USAGE_CLAUDE_WEEKLY_TOKEN_LIMIT=2000 \
  "$ROOT_DIR/plugins/ai_usage_providers/claude_code.sh")"

jq -e '
  .source == "ccusage" and
  .remaining_percent == 75 and
  .is_estimate == true and
  .basis == "ccusage used tokens / configured local tokens limit" and
  .reset_at == "2026-05-12T11:00:00.000Z" and
  .windows["5h"].remaining_percent == 75 and
  .windows["5h"].is_estimate == true and
  .windows.weekly.remaining_percent == 50 and
  .windows.weekly.reset_at == "2026-05-17T00:00:00Z"
' <<<"$output" >/dev/null

echo "ai_usage_claude_provider_test: ok"
