#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin"
printf '0' > "$TMP_DIR/curl-count"

cat > "$TMP_DIR/bin/security" <<'MOCK'
#!/usr/bin/env bash
cat <<'JSON'
{"claudeAiOauth":{"accessToken":"test-token"}}
JSON
MOCK

cat > "$TMP_DIR/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
count_file="$AI_USAGE_TEST_CURL_COUNT"
count="$(cat "$count_file")"
printf '%s' "$((count + 1))" > "$count_file"

out=""
headers=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    -D) headers="$2"; shift 2 ;;
    -w) shift 2 ;;
    *) shift ;;
  esac
done
[[ -n "$headers" ]] && printf 'HTTP/2 429\r\n\r\n' > "$headers"
cat > "$out" <<'JSON'
{"error":{"type":"rate_limit_error","message":"Rate limited. Please try again later."}}
JSON
printf '429'
MOCK

cat > "$TMP_DIR/bin/ccusage" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  blocks)
    cat <<'JSON'
{"blocks":[{"startTime":"2026-06-22T10:00:00.000Z","endTime":"2026-06-22T15:00:00.000Z","isActive":true,"totalTokens":250,"costUSD":1.0}]}
JSON
    ;;
  weekly)
    cat <<'JSON'
{"weekly":[{"period":"2026-06-22","totalTokens":1000,"totalCost":2.0}]}
JSON
    ;;
  *) exit 2 ;;
esac
MOCK
chmod +x "$TMP_DIR/bin/security" "$TMP_DIR/bin/curl" "$TMP_DIR/bin/ccusage"

common_env=(
  PATH="$TMP_DIR/bin:$PATH"
  AI_USAGE_TEST_CURL_COUNT="$TMP_DIR/curl-count"
  AI_USAGE_CLAUDE_API_STATE_FILE="$TMP_DIR/oauth-state.json"
  AI_USAGE_CLAUDE_API_BACKOFF_SECONDS=3600
  AI_USAGE_CLAUDE_5H_TOKEN_LIMIT=1000
  AI_USAGE_CLAUDE_WEEKLY_TOKEN_LIMIT=2000
)

output="$(env "${common_env[@]}" "$ROOT_DIR/plugins/ai_usage_providers/claude_code.sh")"

jq -e '
  .source == "ccusage" and
  .remaining_percent == 75 and
  .is_estimate == true and
  (.message | contains("Claude OAuth usage API rate limited")) and
  .oauth_fallback_reason == "Claude OAuth usage API rate limited: Rate limited. Please try again later." and
  .windows.weekly.remaining_percent == 50 and
  .windows.weekly.reset_at == "2026-06-29T00:00:00Z"
' <<<"$output" >/dev/null

# A second provider run should honor the persisted backoff and not call curl again.
env "${common_env[@]}" "$ROOT_DIR/plugins/ai_usage_providers/claude_code.sh" >/dev/null
[[ "$(cat "$TMP_DIR/curl-count")" == "1" ]]

echo "ai_usage_claude_oauth_rate_limit_test: ok"
