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
  },
  "credits": {
    "has_credits": true,
    "unlimited": false,
    "balance": "150.75"
  },
  "spend_control": { "reached": false }
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
  .windows.weekly.reset_at == 1779135357 and
  .credits.has_credits == true and
  .credits.balance == "150.75" and
  .credits.display_label == "150 credits" and
  .windows.credits.status == "ok" and
  .windows.credits.display_label == "150 credits"
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

cat > "$TMP_DIR/bin/curl" <<'MOCK'
#!/usr/bin/env bash
cat <<'JSON'
{
  "plan_type": "pro",
  "rate_limit": {
    "allowed": true,
    "limit_reached": false,
    "primary_window": null,
    "secondary_window": null
  },
  "credits": {
    "has_credits": true,
    "unlimited": false,
    "balance": "82.4"
  },
  "spend_control": { "reached": false }
}
JSON
MOCK
chmod +x "$TMP_DIR/bin/curl"

credits_output="$(HOME="$TMP_DIR/home" PATH="$TMP_DIR/bin:/usr/bin:/bin" "$ROOT_DIR/plugins/ai_usage_providers/gpt_plus.sh")"

jq -e '
  .source == "codex_wham_usage_api" and
  .plan_type == "pro" and
  .status == "ok" and
  .remaining_percent == null and
  .display_label == "82.4cr" and
  .display_color == "green" and
  .message == "82.4 credits (official Codex/ChatGPT credits balance)" and
  .credits.has_credits == true and
  .credits.balance == "82.4" and
  .windows.credits.status == "ok" and
  .windows.credits.display_label == "82.4 credits"
' <<<"$credits_output" >/dev/null

cat > "$TMP_DIR/bin/curl" <<'MOCK'
#!/usr/bin/env bash
cat <<'JSON'
{
  "plan_type": "self_serve_business_usage_based",
  "rate_limit": null,
  "credits": {
    "has_credits": true,
    "unlimited": false,
    "overage_limit_reached": false,
    "balance": null
  },
  "spend_control": { "reached": false }
}
JSON
MOCK
chmod +x "$TMP_DIR/bin/curl"

usage_based_output="$(HOME="$TMP_DIR/home" PATH="$TMP_DIR/bin:/usr/bin:/bin" "$ROOT_DIR/plugins/ai_usage_providers/gpt_plus.sh")"

jq -e '
  .source == "codex_wham_usage_api" and
  .plan_type == "self_serve_business_usage_based" and
  .status == "ok" and
  .remaining_percent == null and
  .display_label == "cr" and
  .display_color == "green" and
  .credits.has_credits == true and
  .credits.balance == null and
  .windows.credits.status == "ok" and
  .windows.credits.display_label == "Credit usage active"
' <<<"$usage_based_output" >/dev/null

usage_based_manual_balance_output="$(
  HOME="$TMP_DIR/home" \
  PATH="$TMP_DIR/bin:/usr/bin:/bin" \
  AI_USAGE_GPT_CREDITS_BALANCE=82.4 \
  "$ROOT_DIR/plugins/ai_usage_providers/gpt_plus.sh"
)"

jq -e '
  .source == "codex_wham_usage_api" and
  .plan_type == "self_serve_business_usage_based" and
  .status == "ok" and
  .remaining_percent == null and
  .display_label == "≈82.4cr" and
  .is_estimate == true and
  .basis == "manual GPT credits balance; official API confirms Codex account" and
  .credits.balance == "82.4" and
  .windows.credits.display_label == "≈82.4 credits"
' <<<"$usage_based_manual_balance_output" >/dev/null

cat > "$TMP_DIR/bin/curl" <<'MOCK'
#!/usr/bin/env bash
cat <<'JSON'
{
  "plan_type": "pro",
  "credits": {
    "has_credits": true,
    "unlimited": true,
    "balance": null
  }
}
JSON
MOCK
chmod +x "$TMP_DIR/bin/curl"

unlimited_output="$(HOME="$TMP_DIR/home" PATH="$TMP_DIR/bin:/usr/bin:/bin" "$ROOT_DIR/plugins/ai_usage_providers/gpt_plus.sh")"

jq -e '
  .source == "codex_wham_usage_api" and
  .status == "ok" and
  .remaining_percent == null and
  .display_label == "∞cr" and
  .credits.unlimited == true and
  .windows.credits.display_label == "Unlimited credits"
' <<<"$unlimited_output" >/dev/null

echo "ai_usage_gpt_codex_usage_test: ok"
