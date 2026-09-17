#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin"
cat > "$TMP_DIR/credentials.json" <<'JSON'
{"claudeAiOauth":{"accessToken":"expired-token","refreshToken":"refresh-token","expiresAt":1,"refreshTokenExpiresAt":4102444800000,"subscriptionType":"team"}}
JSON
cat > "$TMP_DIR/bin/security" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "find-generic-password" && " $* " == *" -w "* ]]; then
  cat "$AI_USAGE_TEST_CREDENTIALS"
elif [[ "$1" == "find-generic-password" ]]; then
  printf '%s\n' '    "acct"<blob>="test-user"'
elif [[ "$1" == "add-generic-password" ]]; then
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "-w" ]]; then
      printf '%s' "$2" > "$AI_USAGE_TEST_CREDENTIALS"
      exit 0
    fi
    shift
  done
  exit 2
else
  exit 2
fi
MOCK
cat > "$TMP_DIR/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
out=""
url="${!#}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    -D) shift 2 ;;
    -w) shift 2 ;;
    *) shift ;;
  esac
done
if [[ "$url" == "https://platform.claude.com/v1/oauth/token" ]]; then
  cat > "$out" <<'JSON'
{"access_token":"fresh-token","refresh_token":"rotated-refresh-token","expires_in":28800}
JSON
else
  cat > "$out" <<'JSON'
{"five_hour":{"utilization":12,"resets_at":"2026-09-01T12:00:00Z"},"seven_day":{"utilization":21,"resets_at":"2026-09-07T12:00:00Z"}}
JSON
fi
printf '200'
MOCK
chmod +x "$TMP_DIR/bin/security" "$TMP_DIR/bin/curl"

output="$(
  PATH="$TMP_DIR/bin:/usr/bin:/bin" \
  AI_USAGE_TEST_CREDENTIALS="$TMP_DIR/credentials.json" \
  AI_USAGE_CLAUDE_API_STATE_FILE="$TMP_DIR/oauth-state.json" \
  "$ROOT_DIR/plugins/ai_usage_providers/claude_code.sh"
)"

jq -e '
  .source == "claude_oauth_usage_api" and
  .is_estimate == false and
  .remaining_percent == 88 and
  .windows.weekly.remaining_percent == 79
' <<<"$output" >/dev/null
jq -e '
  .claudeAiOauth.accessToken == "fresh-token" and
  .claudeAiOauth.refreshToken == "rotated-refresh-token" and
  .claudeAiOauth.expiresAt > 1
' "$TMP_DIR/credentials.json" >/dev/null

echo "ai_usage_claude_oauth_refresh_test: ok"
