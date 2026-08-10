# AI Usage Visibility Controls Specification

## Problem Statement

The AI usage status items (Claude, GPT/Codex, and DeepSeek) are always defined in the bar configuration. A user cannot quickly choose which of those items is visible without editing the configuration and reloading SketchyBar.

## Goals

- [ ] Provide an always-visible AI settings control with a popup containing one visibility toggle per provider.
- [ ] Apply a provider's visibility change immediately and retain it across SketchyBar reloads and restarts.
- [ ] Keep provider usage collection independent from provider visibility.

## Out of Scope

| Feature | Reason |
| --- | --- |
| Enabling/disabling provider API requests | Visibility must not change data-source configuration. |
| Reordering status items | This feature only controls drawing state. |
| Syncing settings between machines | The configuration is intentionally local. |

---

## User Stories

### P1: Toggle provider visibility ⭐ MVP

**User Story**: As a SketchyBar user, I want to toggle Claude, GPT/Codex, or DeepSeek from an AI settings popup so I can keep only the usage indicators I want in the status bar.

**Why P1**: This is the requested core interaction.

**Acceptance Criteria**:

1. **AIVIS-01** — WHEN the bar loads THEN it SHALL display an AI settings control even when every provider status item is hidden.
2. **AIVIS-02** — WHEN the user opens the settings control THEN it SHALL show Claude, GPT/Codex, and DeepSeek controls with their current visible/hidden state.
3. **AIVIS-03** — WHEN the user selects a provider control THEN the matching status item SHALL immediately toggle between visible and hidden.
4. **AIVIS-04** — WHEN the user toggles a provider THEN no other provider's drawing state SHALL change.

**Independent Test**: Open the settings popup, toggle each provider, and observe only its corresponding compact status item change.

---

### P1: Persist visibility preferences ⭐ MVP

**User Story**: As a SketchyBar user, I want my visibility choices retained so I do not need to repeat them after SketchyBar reloads.

**Why P1**: A quick toggle is not useful if it resets on restart.

**Acceptance Criteria**:

1. **AIVIS-05** — WHEN a provider visibility is changed THEN the system SHALL persist it in the local `ai_usage.env` configuration using `AI_USAGE_<PROVIDER>_VISIBLE=true|false`.
2. **AIVIS-06** — WHEN SketchyBar starts or reloads THEN it SHALL apply persisted visibility values; missing or invalid values SHALL default to visible.
3. **AIVIS-07** — WHEN updating one visibility key THEN unrelated `ai_usage.env` entries SHALL be preserved.

**Independent Test**: Toggle GPT/Codex off, reload SketchyBar, and confirm it remains hidden while the other providers retain their prior state.

---

## Edge Cases

- WHEN `ai_usage.env` does not yet exist THEN toggling a provider SHALL create it safely.
- WHEN every provider is hidden THEN the settings control SHALL remain available.
- WHEN `ai_usage.env` contains comments, blank lines, or non-visibility settings THEN visibility updates SHALL retain them.
- WHEN a visibility value is absent or not `true`/`false` THEN the bar SHALL treat that provider as visible.

## Requirement Traceability

| Requirement ID | Story | Status |
| --- | --- | --- |
| AIVIS-01 | P1: Toggle provider visibility | Complete |
| AIVIS-02 | P1: Toggle provider visibility | Complete |
| AIVIS-03 | P1: Toggle provider visibility | Complete |
| AIVIS-04 | P1: Toggle provider visibility | Complete |
| AIVIS-05 | P1: Persist visibility preferences | Complete |
| AIVIS-06 | P1: Persist visibility preferences | Complete |
| AIVIS-07 | P1: Persist visibility preferences | Complete |

**Coverage**: 7 total, 7 mapped to tasks.

## Success Criteria

- [x] Any provider can be shown or hidden in no more than two clicks from the status bar.
- [x] Visibility survives `sketchybar --reload`.
- [x] The existing provider usage API configuration and refresh behavior are unchanged.
