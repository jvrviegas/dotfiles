#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin"
cat > "$TMP_DIR/bin/security" <<'MOCK'
#!/usr/bin/env bash
cat <<'JSON'
{"claudeAiOauth":{"accessToken":"test-token"}}
JSON
MOCK
cat > "$TMP_DIR/bin/curl" <<'MOCK'
#!/usr/bin/env bash
cat <<'JSON'
{
  "five_hour": { "utilization": 14.0, "resets_at": "2026-05-12T11:30:00.000000+00:00" },
  "seven_day": { "utilization": 10.0, "resets_at": "2026-05-14T08:00:00.000000+00:00" }
}
JSON
MOCK
chmod +x "$TMP_DIR/bin/security" "$TMP_DIR/bin/curl"

output="$(PATH="$TMP_DIR/bin:/usr/bin:/bin" "$ROOT_DIR/plugins/ai_usage_providers/claude_code.sh")"

jq -e '
  .source == "claude_oauth_usage_api" and
  .is_estimate == false and
  .remaining_percent == 86 and
  .basis == "official Claude OAuth usage API utilization" and
  .windows["5h"].remaining_percent == 86 and
  .windows["5h"].used_percent == 14 and
  .windows["5h"].is_estimate == false and
  .windows.weekly.remaining_percent == 90 and
  .windows.weekly.used_percent == 10 and
  .windows.weekly.is_estimate == false
' <<<"$output" >/dev/null

echo "ai_usage_claude_oauth_usage_test: ok"
