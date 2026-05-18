# AI Usage SketchyBar Plugin

- `plugins/ai_usage.sh` aggregates provider JSON into `~/.cache/sketchybar/ai_usage.json` and renders `LABEL=...`, `COLOR=...`, `DETAILS=...`, `STATUS=...` for `items/ai_usage.lua`.
- Claude provider: `plugins/ai_usage_providers/claude_code.sh` first reads the macOS Keychain `Claude Code-credentials` OAuth token and calls `https://api.anthropic.com/api/oauth/usage` for official `five_hour` and `seven_day` utilization/resets. It falls back to `ccusage`/`npx ccusage` if unavailable.
- Claude Code auth status exposes subscription type but not numeric remaining limits. The OAuth usage API does expose utilization. `ccusage` fallback percentages require local limits in `~/.config/sketchybar/ai_usage.env`.
- Claude API control env: `AI_USAGE_CLAUDE_API_ENABLED=false` disables the official OAuth usage API and forces fallbacks.
- Claude UI override env examples: `AI_USAGE_CLAUDE_5H_USED_PERCENT`, `AI_USAGE_CLAUDE_5H_RESET_AT`, `AI_USAGE_CLAUDE_WEEKLY_USED_PERCENT`, `AI_USAGE_CLAUDE_WEEKLY_RESET_AT`. These win over ccusage estimates when API mode is unavailable/disabled.
- Claude estimate fallback env examples: `AI_USAGE_CLAUDE_5H_TOKEN_LIMIT`, `AI_USAGE_CLAUDE_WEEKLY_TOKEN_LIMIT`, or cost mode with `AI_USAGE_CLAUDE_LIMIT_MODE=cost`, `AI_USAGE_CLAUDE_5H_COST_LIMIT`, `AI_USAGE_CLAUDE_WEEKLY_COST_LIMIT`.
- Claude provider emits `windows["5h"]` and `windows.weekly`, which the future popup phase can consume.
- GPT/Codex provider: `plugins/ai_usage_providers/gpt_plus.sh` reads `~/.codex/auth.json` and calls `https://chatgpt.com/backend-api/wham/usage` for official ChatGPT/Codex plan windows. It falls back to manual config if unavailable. Plus accounts may return primary=5h and secondary=weekly; free accounts may return only primary=weekly with `secondary_window: null`, so the provider maps windows by `limit_window_seconds`.
- GPT API control env: `AI_USAGE_GPT_API_ENABLED=false` disables Codex usage API and forces manual fallback.
- GPT manual fallback env examples: `AI_USAGE_GPT_REMAINING_PERCENT`, `AI_USAGE_GPT_5H_REMAINING_PERCENT`, `AI_USAGE_GPT_5H_RESET_AT`, `AI_USAGE_GPT_WEEKLY_REMAINING_PERCENT`, `AI_USAGE_GPT_WEEKLY_RESET_AT`.
- Popup phase: `items/ai_usage.lua` defines popup child rows for Claude/GPT 5-hour and weekly windows. Values come from `plugins/ai_usage.sh popup`, which reads the same normalized cache as the compact label.
- Popup refresh row runs `plugins/ai_usage.sh refresh`, then updates compact and popup labels.
- Phase 7 estimate transparency: providers emit `is_estimate` and `basis`. `plugins/ai_usage.sh render/popup` prefixes estimated values with `≈`; `plugins/ai_usage.sh doctor` explains source and basis.
- `plugins/ai_usage.sh popup` formats reset/update timestamps into local short labels via Node when available.
- User-facing docs live at `docs/ai_usage.md`; README links there.
- Parser/formatter fixture tests: `tests/ai_usage_claude_provider_test.sh`, `tests/ai_usage_gpt_provider_test.sh`, `tests/ai_usage_popup_test.sh`.
