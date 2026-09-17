#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

HOME_DIR="$TMP_DIR/home"
CONFIG_DIR_TEST="$TMP_DIR/config"
mkdir -p "$HOME_DIR/.nvm/versions/node/v12.0.0/bin" "$HOME_DIR/.nvm/versions/node/v24.0.0/bin" "$CONFIG_DIR_TEST/plugins/ai_usage_providers"
ln -s "$ROOT_DIR/plugins/ai_usage_providers/claude_code.sh" "$CONFIG_DIR_TEST/plugins/ai_usage_providers/claude_code.sh"
ln -s "$ROOT_DIR/plugins/ai_usage_providers/gpt_plus.sh" "$CONFIG_DIR_TEST/plugins/ai_usage_providers/gpt_plus.sh"

cat > "$CONFIG_DIR_TEST/ai_usage.env" <<'ENV'
AI_USAGE_CLAUDE_API_ENABLED=false
AI_USAGE_CLAUDE_5H_TOKEN_LIMIT=1000
AI_USAGE_CLAUDE_WEEKLY_TOKEN_LIMIT=2000
AI_USAGE_GPT_ENABLED=false
ENV

cat > "$HOME_DIR/.nvm/versions/node/v12.0.0/bin/npx" <<'MOCK'
#!/usr/bin/env bash
exit 99
MOCK

cat > "$HOME_DIR/.nvm/versions/node/v24.0.0/bin/node" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "${*: -1}" in
  2026-05-12) printf '"2026-05-19T00:00:00Z"' ;;
  *) printf 'null' ;;
esac
MOCK

cat > "$HOME_DIR/.nvm/versions/node/v24.0.0/bin/npx" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == "ccusage" ]] || exit 2
case "$2" in
  blocks)
    cat <<'JSON'
{"blocks":[{"startTime":"2026-05-12T06:00:00.000Z","endTime":"2026-05-12T11:00:00.000Z","isActive":true,"totalTokens":250,"costUSD":1}]}
JSON
    ;;
  weekly)
    cat <<'JSON'
{"weekly":[{"period":"2026-05-12","totalTokens":1000,"totalCost":2}]}
JSON
    ;;
  *) exit 2 ;;
esac
MOCK
chmod +x "$HOME_DIR/.nvm/versions/node/v12.0.0/bin/npx" "$HOME_DIR/.nvm/versions/node/v24.0.0/bin/node" "$HOME_DIR/.nvm/versions/node/v24.0.0/bin/npx"

output="$(HOME="$HOME_DIR" CONFIG_DIR="$CONFIG_DIR_TEST" XDG_CACHE_HOME="$TMP_DIR/cache" PATH="/usr/bin:/bin" "$ROOT_DIR/plugins/ai_usage.sh" refresh)"

grep -q '^CLAUDE_LABEL=≈75%' <<<"$output"
jq -e '.providers.claude.source == "ccusage" and .providers.claude.remaining_percent == 75 and .providers.claude.windows.weekly.reset_at == "2026-05-19T00:00:00Z"' "$TMP_DIR/cache/sketchybar/ai_usage.json" >/dev/null

echo "ai_usage_sketchybar_path_test: ok"
