# AI Usage Split Labels Progress

Goal: split the AI monitor bar label so Claude and GPT can show independent colors instead of sharing one global worst-case color.

## Progress

- [x] Identify issue: `plugins/ai_usage.sh render` emits one `COLOR`, so both accounts inherit the same status color.
- [x] Choose approach: separate Claude and GPT bar items/labels while keeping the popup shared.
- [x] Update `plugins/ai_usage.sh` to emit provider-specific render fields:
  - [x] `CLAUDE_LABEL`
  - [x] `CLAUDE_COLOR`
  - [x] `GPT_LABEL`
  - [x] `GPT_COLOR`
  - [x] Keep legacy `LABEL` / `COLOR` if useful for compatibility.
- [x] Update `items/ai_usage.lua`:
  - [x] Remove the standalone robot/root icon section; anchor the popup on the Claude provider item.
  - [x] Add separate Claude label item using `:claude:` app icon with `sketchybar-app-font`.
  - [x] Add separate GPT label item using `:openai:` app icon with `sketchybar-app-font`.
  - [x] Apply `CLAUDE_COLOR` only to Claude.
  - [x] Apply `GPT_COLOR` only to GPT.
  - [x] Ensure click/refresh popup behavior still works.
- [x] Update tests:
  - [x] Add assertions for provider-specific labels/colors.
  - [x] Preserve popup assertions.
- [x] Run verification:
  - [x] `tests/ai_usage_estimate_render_test.sh`
  - [x] `tests/ai_usage_popup_test.sh`
  - [x] Provider tests if render changes affect cache assumptions.
- [ ] Manual check in SketchyBar:
  - [ ] Claude <= 50%, GPT > 50% renders Claude yellow/green/red independently.
  - [ ] GPT <= 50%, Claude > 50% renders GPT yellow/green/red independently.
  - [ ] Popup still opens and refresh still works.

## Notes

Current behavior uses the minimum remaining percentage across all OK providers to choose one global color. That is useful for an overall alert but misleading when displayed next to multiple accounts. Separate labels make the warning local to the affected account.
