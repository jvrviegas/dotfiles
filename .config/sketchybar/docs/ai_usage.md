# AI Usage SketchyBar Item

This item displays AI subscription usage in SketchyBar.

- Compact bar label: `C:<claude> G:<gpt>`
- Popup: Claude and GPT Plus 5-hour and weekly windows
- Cache: `~/.cache/sketchybar/ai_usage.json`
- Local config: `~/.config/sketchybar/ai_usage.env`

## Important accuracy notes

### Claude Code

Claude Code usage is read automatically from the official Claude OAuth usage API used by Claude Code:

```text
https://api.anthropic.com/api/oauth/usage
```

The provider obtains the Claude Code OAuth access token from macOS Keychain entry `Claude Code-credentials` and calls the API locally. The API returns official plan-limit utilization for:

- `five_hour`
- `seven_day`

If the OAuth usage API is unavailable, the provider falls back to `ccusage` / `npx ccusage`. The fallback provides real local token/cost usage, but remaining percentages are estimates calculated from configured local limits:

```text
remaining % = 100 - used / configured_limit * 100
```

Fallback estimated values are prefixed with `≈` in the bar/popup and include a `basis` field in the cache.

### GPT Plus

GPT Plus/Codex usage is read automatically from Codex's ChatGPT plan usage endpoint when `codex login` is configured:

```text
https://chatgpt.com/backend-api/wham/usage
```

The provider reads `~/.codex/auth.json` and uses the Codex access token. This endpoint returns real primary (5-hour) and secondary (weekly) plan-limit usage for the signed-in ChatGPT/Codex account. Manual GPT values remain available as fallback and are shown as estimates with `≈`.

## Setup

Create or edit:

```sh
~/.config/sketchybar/ai_usage.env
```

### Claude automatic config

No Claude config is required for normal operation if you are logged in through Claude Code. The provider reads the OAuth token from macOS Keychain and calls the usage API automatically.

To force fallback mode for debugging:

```sh
AI_USAGE_CLAUDE_API_ENABLED=false
```

### Claude manual UI fallback config

If the OAuth usage API is unavailable, you can still copy displayed `used` percentages into local overrides. Example for a screen showing `13% used` current session and `10% used` weekly:

```sh
AI_USAGE_CLAUDE_5H_USED_PERCENT=13
AI_USAGE_CLAUDE_5H_RESET_AT="in 11 min"
AI_USAGE_CLAUDE_WEEKLY_USED_PERCENT=10
AI_USAGE_CLAUDE_WEEKLY_RESET_AT="Thu 9:00 AM"
```

These values override the `ccusage` token/cost estimate when API mode is unavailable/disabled.

### Claude token-based fallback config

```sh
AI_USAGE_CLAUDE_LIMIT_MODE=tokens
AI_USAGE_CLAUDE_5H_TOKEN_LIMIT=100000000
AI_USAGE_CLAUDE_WEEKLY_TOKEN_LIMIT=1000000000
```

### Claude cost-based config

```sh
AI_USAGE_CLAUDE_LIMIT_MODE=cost
AI_USAGE_CLAUDE_5H_COST_LIMIT=50
AI_USAGE_CLAUDE_WEEKLY_COST_LIMIT=500
```

### GPT automatic config

No GPT config is required if you are logged into Codex with ChatGPT:

```sh
codex login status
```

To force manual fallback mode:

```sh
AI_USAGE_GPT_API_ENABLED=false
```

### GPT manual fallback config

```sh
AI_USAGE_GPT_REMAINING_PERCENT=40
AI_USAGE_GPT_5H_REMAINING_PERCENT=40
AI_USAGE_GPT_5H_RESET_AT="2026-05-12T18:00:00Z"
AI_USAGE_GPT_WEEKLY_REMAINING_PERCENT=85
AI_USAGE_GPT_WEEKLY_RESET_AT="2026-05-17T00:00:00Z"
```

## Behavior

- Click the bar item to toggle the popup.
- Click the popup refresh row to force-refresh provider data.
- Automatic refresh interval defaults to 300 seconds / 5 minutes.
- Stale cache is displayed with a `~` prefix.
- Errors display as `!`.
- Disabled providers display as `off`.
- Unknown values display as `?`.

## Manual commands

Refresh:

```sh
~/.config/sketchybar/plugins/ai_usage.sh refresh
sketchybar --trigger forced
```

Inspect cache:

```sh
~/.config/sketchybar/plugins/ai_usage.sh cache | jq .
```

Inspect popup payload:

```sh
~/.config/sketchybar/plugins/ai_usage.sh popup
```

Explain data sources and estimate basis:

```sh
~/.config/sketchybar/plugins/ai_usage.sh doctor
```

Reload SketchyBar:

```sh
sketchybar --reload
```

## Troubleshooting

### Why does the bar show `≈`?

`≈` means the value is estimated, not an official provider quota. Claude values from `claude_oauth_usage_api` and GPT/Codex values from `codex_wham_usage_api` are official and do not show `≈`. Claude fallback estimates use real `ccusage` usage divided by configured local limits. GPT fallback estimates are manual user-provided values.

Run diagnostics:

```sh
~/.config/sketchybar/plugins/ai_usage.sh doctor
```

### Claude shows `C:?`

Check whether Claude limits are configured:

```sh
grep AI_USAGE_CLAUDE ~/.config/sketchybar/ai_usage.env
```

Then inspect the provider:

```sh
~/.config/sketchybar/plugins/ai_usage_providers/claude_code.sh | jq .
```

If the provider says `ccusage unavailable`, the OAuth usage API was unavailable and the fallback could not run. Ensure Claude Code is logged in (`claude auth status`) and `npx` is available or install `ccusage`.

### GPT shows `G:?`

Check Codex login first:

```sh
codex login status
```

Then inspect the provider:

```sh
~/.config/sketchybar/plugins/ai_usage_providers/gpt_plus.sh | jq .
```

If the Codex usage API is unavailable, add manual fallback values such as `AI_USAGE_GPT_REMAINING_PERCENT` or `AI_USAGE_GPT_5H_REMAINING_PERCENT` to `ai_usage.env`.

### Popup values are old

Force refresh:

```sh
~/.config/sketchybar/plugins/ai_usage.sh refresh
sketchybar --trigger forced
```

### Bar reloads but values do not change

Inspect the cache and provider output:

```sh
~/.config/sketchybar/plugins/ai_usage.sh cache | jq .providers
~/.config/sketchybar/plugins/ai_usage.sh render
```

## Security

Do not commit `ai_usage.env`. It is ignored by this repo and is intended for local-only configuration. Do not add browser cookies, ChatGPT session tokens, or API keys to this plugin.
