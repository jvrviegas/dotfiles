# AI Usage Visibility Controls Tasks

**Spec**: `.specs/features/ai-usage-visibility-controls/spec.md`  
**Status**: Complete

---

## Design Decisions

- Persist only presentation preferences in the existing local-only `ai_usage.env` file:
  `AI_USAGE_CLAUDE_VISIBLE`, `AI_USAGE_GPT_VISIBLE`, and `AI_USAGE_DEEPSEEK_VISIBLE`.
- A new shell helper owns reads and atomic single-key updates so Lua does not parse or rewrite shell configuration.
- Provider items remain registered and continue to refresh usage data; toggles change only SketchyBar's `drawing` property.
- A dedicated settings item is always drawn, so all providers can be hidden without losing the way to restore them.

## Execution Plan

```text
T1 ──→ T2 ──→ T3 ──→ T4
```

## Task Breakdown

### T1: Add a local visibility-state helper

**What**: Create a shell helper that reads normalized visibility state and atomically toggles one provider key while preserving unrelated `ai_usage.env` content.

**Where**: `plugins/ai_usage_visibility.sh`, `tests/ai_usage_visibility_test.sh`

**Depends on**: None  
**Reuses**: `plugins/ai_usage.sh` configuration-file location conventions  
**Requirement**: AIVIS-05, AIVIS-06, AIVIS-07

**Tools**:
- MCP: NONE
- Skill: `codenavi`

**Done when**:
- [x] `get` emits boolean visibility for Claude, GPT, and DeepSeek.
- [x] Missing or invalid visibility values resolve to `true`.
- [x] `toggle <provider>` updates only that provider's key, creates the file when absent, and preserves other entries.
- [x] The write is atomic and leaves no temporary file after success.
- [x] Test passes: `bash tests/ai_usage_visibility_test.sh`.

**Tests**: shell fixture test  
**Gate**: `bash tests/ai_usage_visibility_test.sh`  
**Commit**: `feat(ai-usage): add persisted visibility state helper`

---

### T2: Add the always-visible AI settings control

**What**: Add the settings status item and popup rows, initialize provider drawing from the helper, and wire popup-row clicks to immediate provider-only drawing updates plus persistence.

**Where**: `items/ai_usage.lua`

**Depends on**: T1  
**Reuses**: `provider_item()`, `popup_row()`, and existing `sbar.exec` callback pattern in `items/ai_usage.lua`  
**Requirement**: AIVIS-01, AIVIS-02, AIVIS-03, AIVIS-04, AIVIS-06

**Tools**:
- MCP: NONE
- Skill: `codenavi`

**Done when**:
- [x] A settings control stays visible independently of all provider items.
- [x] Its popup has one current-state row per provider.
- [x] Clicking a row persists the selected state and changes only its matching provider item's `drawing` state.
- [x] Existing provider label refresh, provider popups, and refresh action still work.
- [x] Lua syntax check passes: `luac -p items/ai_usage.lua`.

**Tests**: syntax/manual SketchyBar interaction  
**Gate**: `luac -p items/ai_usage.lua`  
**Commit**: `feat(ai-usage): add provider visibility settings popup`

---

### T3: Document configuration and interaction

**What**: Document the settings popup, persisted visibility variables, defaults, and recovery path when all provider items are hidden.

**Where**: `docs/ai_usage.md`

**Depends on**: T2  
**Reuses**: existing `ai_usage.env` setup and troubleshooting sections  
**Requirement**: AIVIS-01, AIVIS-05, AIVIS-06

**Tools**:
- MCP: NONE
- Skill: NONE

**Done when**:
- [x] Documentation lists all three `AI_USAGE_*_VISIBLE` variables and their default.
- [x] Documentation explains settings-popup usage and that it remains visible when all providers are hidden.
- [x] Documentation distinguishes visibility from provider/API enablement.

**Tests**: documentation review  
**Gate**: `rg -n 'AI_USAGE_(CLAUDE|GPT|DEEPSEEK)_VISIBLE' docs/ai_usage.md`  
**Commit**: `docs(ai-usage): document visibility controls`

---

### T4: Run regression checks and verify persistence

**What**: Run the focused new test and existing AI usage regression tests, then validate the reload persistence workflow in the running SketchyBar instance.

**Where**: no source change expected

**Depends on**: T1, T2, T3  
**Reuses**: existing `tests/ai_usage_*_test.sh` suite  
**Requirement**: AIVIS-01 through AIVIS-07

**Tools**:
- MCP: NONE
- Skill: `codenavi`

**Done when**:
- [x] Focused visibility helper test passes.
- [x] Existing AI usage test scripts pass.
- [x] `sketchybar --reload` preserves a deliberately toggled provider state.
- [x] Manual checks confirm the settings item remains after all providers are hidden.

**Tests**: regression + manual runtime validation  
**Gate**: `for test in tests/ai_usage_*_test.sh; do bash "$test"; done`  
**Commit**: none (verification only)

---

## Dependency Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| --- | --- | --- | --- |
| T1 | None | Root | ✅ Match |
| T2 | T1 | T1 → T2 | ✅ Match |
| T3 | T2 | T2 → T3 | ✅ Match |
| T4 | T1, T2, T3 | T3 after the T1 → T2 → T3 chain | ✅ Match |

## Test Co-location Validation

No `.specs/codebase/TESTING.md` exists. Test types below follow the repository's existing executable shell-fixture convention.

| Task | Code Layer Modified | Required Test | Task Says | Status |
| --- | --- | --- | --- | --- |
| T1 | Shell config-state helper | Shell fixture | Shell fixture test | ✅ OK |
| T2 | SketchyBar Lua item | Lua syntax + runtime interaction | Syntax/manual interaction | ✅ OK |
| T3 | Documentation | Documentation check | Documentation review | ✅ OK |
| T4 | No code layer | Regression validation | Regression + manual | ✅ OK |

## Task Granularity Check

| Task | Scope | Status |
| --- | --- | --- |
| T1 | One state-helper capability and its co-located fixture | ✅ Granular |
| T2 | One SketchyBar UI module | ✅ Granular |
| T3 | One documentation file | ✅ Granular |
| T4 | Verification only | ✅ Granular |
