#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/config/plugins/ai_usage_providers" "$TMP_DIR/cache"

for provider in claude_code gpt_plus deepseek; do
  cat > "$TMP_DIR/config/plugins/ai_usage_providers/$provider.sh" <<MOCK
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '$provider' >> '$TMP_DIR/provider-calls'
sleep 0.1
jq -n '{enabled: true, remaining_percent: 50, status: "ok", message: "50% left"}'
MOCK
  chmod +x "$TMP_DIR/config/plugins/ai_usage_providers/$provider.sh"
done

pids=()
for _ in 1 2 3 4 5 6; do
  CONFIG_DIR="$TMP_DIR/config" XDG_CACHE_HOME="$TMP_DIR/cache" \
    "$ROOT_DIR/plugins/ai_usage.sh" render > /dev/null &
  pids+=("$!")
done

for pid in "${pids[@]}"; do
  wait "$pid"
done

[[ "$(grep -c '^claude_code$' "$TMP_DIR/provider-calls")" == "1" ]]
[[ "$(grep -c '^gpt_plus$' "$TMP_DIR/provider-calls")" == "1" ]]
[[ "$(grep -c '^deepseek$' "$TMP_DIR/provider-calls")" == "1" ]]
jq -e '.providers.claude.remaining_percent == 50 and .providers.gpt.remaining_percent == 50 and .providers.deepseek.remaining_percent == 50' \
  "$TMP_DIR/cache/sketchybar/ai_usage.json" >/dev/null
[[ ! -d "$TMP_DIR/cache/sketchybar/ai_usage.lock" ]]

echo "ai_usage_cache_lock_test: ok"
