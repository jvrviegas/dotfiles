# SketchyBar Structure

- Entrypoint: `init.lua` loads `bar`, `default`, and `items`.
- Item registration list: `items/init.lua`.
- Lua items use global `sbar`, `colors.lua`, and `settings.lua`.
- Shell plugins live in `plugins/` and can be called from Lua via `sbar.exec(...)`.
- Existing right-side rounded status styling is visible in `items/calendar.lua` and `items/stats.lua`.
- `items/widgets/` contains additional Lua widget patterns including callbacks and brackets.
