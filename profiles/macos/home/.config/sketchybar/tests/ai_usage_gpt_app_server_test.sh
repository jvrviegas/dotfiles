#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/home/.codex" "$TMP_DIR/bin"
cat > "$TMP_DIR/home/.codex/auth.json" <<'JSON'
{"tokens":{"access_token":"expired-test-token","account_id":"account-test"}}
JSON
cat > "$TMP_DIR/bin/codex" <<'PY'
#!/usr/bin/env python3
import json
import sys

if len(sys.argv) < 2 or sys.argv[1] != "app-server":
    print("codex-cli 0.147.0")
    raise SystemExit(0)

for line in sys.stdin:
    request = json.loads(line)
    if request.get("method") == "initialize":
        print(json.dumps({"id": request["id"], "result": {"userAgent": "test"}}), flush=True)
    elif request.get("method") == "account/rateLimits/read":
        print(json.dumps({
            "id": request["id"],
            "result": {
                "rateLimits": {
                    "primary": {"usedPercent": 8, "windowDurationMins": 300, "resetsAt": 1788182311},
                    "secondary": {"usedPercent": 1, "windowDurationMins": 10080, "resetsAt": 1788769111},
                    "credits": {"hasCredits": False, "unlimited": False, "balance": "0"},
                    "spendControlReached": False,
                    "planType": "plus"
                }
            }
        }), flush=True)
        break
PY
cat > "$TMP_DIR/bin/curl" <<'MOCK'
#!/usr/bin/env bash
exit 22
MOCK
chmod +x "$TMP_DIR/bin/codex" "$TMP_DIR/bin/curl"

output="$(HOME="$TMP_DIR/home" PATH="$TMP_DIR/bin:/usr/bin:/bin" "$ROOT_DIR/plugins/ai_usage_providers/gpt_plus.sh")"

jq -e '
  .source == "codex_app_server" and
  .is_estimate == false and
  .plan_type == "plus" and
  .remaining_percent == 92 and
  .windows["5h"].remaining_percent == 92 and
  .windows["5h"].reset_at == 1788182311 and
  .windows.weekly.remaining_percent == 99 and
  .windows.weekly.reset_at == 1788769111
' <<<"$output" >/dev/null

echo "ai_usage_gpt_app_server_test: ok"
