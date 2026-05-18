# AI Subscription Usage SketchyBar Plugin Plan

## Objective

Add a SketchyBar item that shows remaining AI subscription usage at a glance for:

- Claude Code subscription limits
- ChatGPT / GPT Plus limits

The implementation should be phaseable, safe around credentials/session data, and resilient when a provider has no supported usage API.

## Current Repo Context

- SketchyBar config entrypoint: `init.lua`
- Items are registered from `items/init.lua`
- Lua-based items already exist, e.g. `items/calendar.lua`, `items/stats.lua`
- Shell plugins live under `plugins/`
- Existing item style uses `colors.lua`, `settings.lua`, rounded `bg1` backgrounds, and right-side status items

## Key Unknowns / Risks

| Risk | Impact | Mitigation |
|---|---:|---|
| Claude Code usage source may not expose a stable local/API format | High | Start with a provider discovery spike; prefer official/local CLI output if available; isolate parsing in one script |
| ChatGPT Plus usage/limits may not have an official public API | High | Design provider as optional; support manual limit config or browser/session-derived script only if explicitly chosen |
| Usage windows differ by model/provider | Medium | Normalize into a common provider schema with labels, percentage remaining, reset time, and status |
| Storing cookies/tokens can be sensitive | High | Do not store credentials in repo; use macOS Keychain or environment variables; document setup |
| Frequent polling could trigger rate limits or slow the bar | Medium | Cache provider results; poll infrequently; render stale/error states gracefully |

## Target UX

Initial compact display:

```text
󰚩 C:72% G:40%
```

Possible expanded tooltip / popup later:

```text
Claude Code: 72% left · resets 14:30
GPT Plus: 40% left · GPT-4o resets 18:00
```

Popup menu target:

```text
Claude Code
  5h window: 72% left · resets 14:30
  Weekly:    61% left · resets Mon 00:00

GPT Plus
  5h window: 40% left · resets 18:00
  Weekly:    85% left · resets Mon 00:00
```

Status colors:

- Green/primary: healthy, `> 50%` left
- Yellow: warning, `20–50%` left
- Red: low, `< 20%` left
- Gray/tertiary: unknown, stale, disabled, or provider error

## Implementation Architecture

```text
items/ai_usage.lua
  └─ creates SketchyBar item
  └─ subscribes to routine/forced updates
  └─ runs plugins/ai_usage.sh

plugins/ai_usage.sh
  └─ reads cached normalized usage JSON
  └─ refreshes cache when stale
  └─ calls provider scripts

plugins/ai_usage_providers/claude_code.sh
plugins/ai_usage_providers/gpt_plus.sh
  └─ provider-specific collection/parsing

~/.cache/sketchybar/ai_usage.json
  └─ normalized cache, not committed

~/.config/sketchybar/ai_usage.env
  └─ local user config, not committed
```

Normalized provider output:

```json
{
  "providers": {
    "claude": {
      "enabled": true,
      "label": "C",
      "remaining_percent": 72,
      "reset_at": "2026-05-12T14:30:00-03:00",
      "status": "ok",
      "message": "72% left",
      "windows": {
        "5h": {
          "remaining_percent": 72,
          "reset_at": "2026-05-12T14:30:00-03:00",
          "status": "ok",
          "message": "72% left"
        },
        "weekly": {
          "remaining_percent": 61,
          "reset_at": "2026-05-18T00:00:00-03:00",
          "status": "ok",
          "message": "61% left"
        }
      }
    },
    "gpt": {
      "enabled": true,
      "label": "G",
      "remaining_percent": 40,
      "reset_at": null,
      "status": "ok",
      "message": "40% left"
    }
  },
  "updated_at": "2026-05-12T10:00:00-03:00"
}
```

## Phase 0 — Discovery Spike

- [x] Identify the best local/official source for Claude Code subscription usage.
  - Candidate checks: Claude Code CLI status/output, local config/cache files, existing tools such as `ccusage` if installed.
  - Acceptance: official Claude OAuth usage API (`https://api.anthropic.com/api/oauth/usage`) provides `five_hour` and `seven_day` utilization/resets. `ccusage`/`npx ccusage` remains as fallback for local usage estimates.
- [x] Identify whether GPT Plus usage can be obtained from an official or stable source.
  - Acceptance: Codex/ChatGPT plan usage is available via `https://chatgpt.com/backend-api/wham/usage` using `~/.codex/auth.json` access token from `codex login`. Browser cookie scraping is not needed.
- [ ] Decide cache TTL and update frequency.
  - Acceptance: values recorded in this plan or future README section.
- [ ] Decide credential/session handling.
  - Acceptance: no secrets committed; all sensitive setup lives outside the repo.

## Phase 1 — Skeleton Bar Item

- [x] Add `items/ai_usage.lua` using existing styling patterns from `items/calendar.lua` / `items/stats.lua`.
- [x] Register it in `items/init.lua`.
- [x] Add `plugins/ai_usage.sh` that initially returns mocked/static values.
- [x] Render compact label for both providers.
- [x] Add click action to force refresh or open a provider dashboard.

Acceptance criteria:

- [x] `sketchybar --reload` succeeds.
- [x] AI usage item appears on the right side.
- [x] Mock/manual values are visible and color thresholds work.
- [x] Missing plugin/cache data renders `C:? G:?` instead of breaking the bar.

## Phase 2 — Cache + Normalization Layer

- [x] Implement cache file at `~/.cache/sketchybar/ai_usage.json`.
- [x] Implement TTL-based refresh in `plugins/ai_usage.sh`.
- [x] Implement provider script contract: each provider emits normalized JSON or a parseable line protocol.
- [x] Add robust error states: `ok`, `unknown`, `stale`, `disabled`, `error`.
- [x] Add local config file support: `~/.config/sketchybar/ai_usage.env`.

Acceptance criteria:

- [x] Provider failures do not block SketchyBar rendering.
- [x] Cached values display when live refresh fails.
- [x] Stale/error states are visually distinct.
- [x] No secret/token values are written into repo files.

## Phase 3 — Claude Code Provider

- [x] Implement `plugins/ai_usage_providers/claude_code.sh` based on the Phase 0 source.
- [x] Parse remaining usage, current window, and reset time when available.
- [x] Map unavailable/ambiguous data to `unknown` with a short message.
- [x] Add a manual override path if Claude usage cannot be queried reliably.

Acceptance criteria:

- [x] Provider returns valid normalized data with real Claude Code usage.
- [x] Handles logged-out/no-data cases gracefully.
- [x] Reset time is displayed when available.
- [x] Unit-like shell test fixtures can validate parser behavior with redacted samples.

## Phase 4 — GPT Plus Provider

- [x] Implement `plugins/ai_usage_providers/gpt_plus.sh` using the selected Phase 0 approach.
- [x] If no stable source exists, implement a disabled/manual mode with clear display text.
- [x] Support model-specific limits if the source exposes them. Codex source exposes primary 5h and secondary weekly windows; manual 5h/weekly fields remain as fallback.
- [x] Avoid storing browser cookies/session tokens in this repo.

Acceptance criteria:

- [x] Provider returns valid normalized data or a clear unsupported/manual state.
- [x] Bar remains useful even if GPT Plus usage cannot be automated.
- [x] Any required setup steps are documented.

## Phase 5 — Popup Menu for 5h + Weekly Limits

- [x] Extend the normalized provider schema with `windows.5h` and `windows.weekly` for each provider.
- [x] Update Claude provider to populate 5-hour and weekly remaining limits when the source exposes them.
- [x] Update GPT Plus provider to populate 5-hour and weekly remaining limits when the source exposes them. No stable source found; manual 5h/weekly values are populated when configured.
- [x] Add popup child items under `ai_usage` for provider headings and per-window rows.
- [x] Change click behavior to toggle the popup; use an alternate click or popup row to force refresh.
- [x] Display window-specific reset times and statuses.
- [x] Add manual override variables for popup rows, e.g. `AI_USAGE_CLAUDE_5H_REMAINING_PERCENT`, `AI_USAGE_CLAUDE_WEEKLY_REMAINING_PERCENT`, `AI_USAGE_GPT_5H_REMAINING_PERCENT`, `AI_USAGE_GPT_WEEKLY_REMAINING_PERCENT`.

Acceptance criteria:

- [x] Clicking the AI usage item opens a popup menu.
- [x] Popup shows Claude Code 5h and weekly rows.
- [x] Popup shows GPT Plus 5h and weekly rows.
- [x] Unknown/unavailable windows render as `?` or `unsupported`, not blank.
- [x] Popup values update from the same cache as the compact bar label.
- [x] Force refresh remains available without losing popup functionality.

## Phase 6 — Polish + Documentation

- [x] Add `README` section or `docs/ai_usage.md` with setup instructions.
- [x] Document config variables, cache location, refresh behavior, and security notes.
- [x] Document popup behavior and 5h/weekly window semantics.
- [x] Add hover behavior if supported by current SketchyBar setup. Skipped intentionally: current interaction is click-to-toggle popup, matching existing widget patterns.
- [x] Tune labels/icons/colors to fit current theme.
- [x] Add troubleshooting commands.

Acceptance criteria:

- [x] A fresh setup can follow the docs and enable the item.
- [x] Common failures have documented remedies.
- [x] Reloading SketchyBar does not require manual cache cleanup.

## Phase 7 — Accuracy / Estimate Transparency

- [x] Add automatic official Claude OAuth usage API source for real plan-limit utilization.
- [x] Add Claude UI plan-limit overrides so screenshot values can supersede ccusage estimates when API mode is unavailable/disabled.
- [x] Add explicit `is_estimate` metadata to provider outputs.
- [x] Add `basis` metadata explaining how each percentage was calculated.
- [x] Prefix estimated compact and popup percentages with `≈`.
- [x] Add `plugins/ai_usage.sh doctor` diagnostics for source/status/basis.
- [x] Document estimate semantics and diagnostics.
- [x] Add tests for estimate rendering and diagnostics.

Acceptance criteria:

- [x] Users can tell estimated values apart from official values at a glance.
- [x] Diagnostics explain Claude and GPT data sources without exposing secrets.
- [x] Existing provider/popup tests still pass.

## Suggested File Changes

| File | Action |
|---|---|
| `items/ai_usage.lua` | New SketchyBar item and popup menu |
| `items/init.lua` | Require the new item |
| `plugins/ai_usage.sh` | New aggregator/cache/render script with popup/window data |
| `plugins/ai_usage_providers/claude_code.sh` | New Claude provider |
| `plugins/ai_usage_providers/gpt_plus.sh` | New GPT Plus provider |
| `docs/ai_usage.md` or `README.org` | Setup and troubleshooting docs |
| `.gitignore` if present/needed | Ensure local env/cache files are ignored |

## Definition of Done

- [x] The bar shows Claude Code and GPT Plus usage/remaining status in one compact item.
- [x] Clicking the item opens a popup with 5-hour and weekly limits for both providers.
- [x] Data refreshes automatically without noticeable bar lag.
- [x] Provider errors degrade gracefully.
- [x] Secrets/session material are never committed.
- [x] Setup and troubleshooting are documented.
- [x] Implementation matches current SketchyBar Lua/shell style.
