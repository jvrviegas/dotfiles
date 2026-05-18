#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/home/.codex" "$TMP_DIR/bin"
cat > "$TMP_DIR/home/.codex/auth.json" <<'JSON'
{"tokens":{"access_token":"test-token"}}
JSON
cat > "$TMP_DIR/bin/curl" <<'MOCK'
#!/usr/bin/env bash
cat <<'JSON'
{
  "plan_type": "plus",
  "rate_limit": {
    "primary_window": {
      "used_percent": 43,
      "limit_window_seconds": 18000,
      "reset_at": 1778604374
    },
    "secondary_window": {
      "used_percent": 28,
      "limit_window_seconds": 604800,
      "reset_at": 1779135357
    }
  }
}
JSON
MOCK
cat > "$TMP_DIR/bin/codex" <<'MOCK'
#!/usr/bin/env bash
echo 'codex-cli 0.128.0'
MOCK
chmod +x "$TMP_DIR/bin/curl" "$TMP_DIR/bin/codex"

output="$(HOME="$TMP_DIR/home" PATH="$TMP_DIR/bin:/usr/bin:/bin" "$ROOT_DIR/plugins/ai_usage_providers/gpt_plus.sh")"

jq -e '
  .source == "codex_wham_usage_api" and
  .is_estimate == false and
  .plan_type == "plus" and
  .remaining_percent == 57 and
  .windows["5h"].remaining_percent == 57 and
  .windows["5h"].used_percent == 43 and
  .windows["5h"].reset_at == 1778604374 and
  .windows.weekly.remaining_percent == 72 and
  .windows.weekly.used_percent == 28 and
  .windows.weekly.reset_at == 1779135357
' <<<"$output" >/dev/null

cat > "$TMP_DIR/bin/curl" <<'MOCK'
#!/usr/bin/env bash
cat <<'JSON'
{
  "plan_type": "free",
  "rate_limit": {
    "allowed": true,
    "limit_reached": false,
    "primary_window": {
      "used_percent": 15,
      "limit_window_seconds": 604800,
      "reset_after_seconds": 604109,
      "reset_at": 1779465951
    },
    "secondary_window": null
  }
}
JSON
MOCK
chmod +x "$TMP_DIR/bin/curl"

free_output="$(HOME="$TMP_DIR/home" PATH="$TMP_DIR/bin:/usr/bin:/bin" "$ROOT_DIR/plugins/ai_usage_providers/gpt_plus.sh")"

jq -e '
  .source == "codex_wham_usage_api" and
  .plan_type == "free" and
  .remaining_percent == 85 and
  .windows["5h"].status == "unknown" and
  .windows["5h"].remaining_percent == null and
  .windows.weekly.status == "ok" and
  .windows.weekly.remaining_percent == 85 and
  .windows.weekly.used_percent == 15 and
  .windows.weekly.reset_at == 1779465951
' <<<"$free_output" >/dev/null

echo "ai_usage_gpt_codex_usage_test: ok"
