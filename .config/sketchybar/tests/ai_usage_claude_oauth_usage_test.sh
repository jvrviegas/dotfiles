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
set -euo pipefail
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
[[ -n "$headers" ]] && printf 'HTTP/2 200\r\n\r\n' > "$headers"
cat > "$out" <<'JSON'
{
  "five_hour": { "utilization": 14.0, "resets_at": "2026-05-12T11:30:00.000000+00:00" },
  "seven_day": { "utilization": 10.0, "resets_at": "2026-05-14T08:00:00.000000+00:00" },
  "limits": [
    { "kind": "session", "group": "session", "percent": 14, "resets_at": "2026-05-12T11:30:00.000000+00:00", "scope": null },
    { "kind": "weekly_all", "group": "weekly", "percent": 10, "resets_at": "2026-05-14T08:00:00.000000+00:00", "scope": null },
    { "kind": "weekly_scoped", "group": "weekly", "percent": 25, "resets_at": "2026-05-14T08:00:00.000000+00:00", "scope": { "model": { "id": null, "display_name": "Fable" }, "surface": null } }
  ]
}
JSON
printf '200'
MOCK
chmod +x "$TMP_DIR/bin/security" "$TMP_DIR/bin/curl"

output="$(PATH="$TMP_DIR/bin:/usr/bin:/bin" AI_USAGE_CLAUDE_API_STATE_FILE="$TMP_DIR/oauth-state.json" "$ROOT_DIR/plugins/ai_usage_providers/claude_code.sh")"

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
  .windows.weekly.is_estimate == false and
  .windows.weekly_fable.remaining_percent == 75 and
  .windows.weekly_fable.used_percent == 25 and
  .windows.weekly_fable.is_estimate == false
' <<<"$output" >/dev/null

echo "ai_usage_claude_oauth_usage_test: ok"
