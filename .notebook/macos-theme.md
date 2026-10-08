# macOS theme deployment

Entry: `profiles/macos/profile.sh:profile_install_config()`.
Flow: `lib/deploy.sh:deploy_common_home()` → macOS overlay; profile files win.

- Shared switcher remains in `home/common/.local/bin/theme-switch`; macOS override in `profiles/macos/home/.local/bin/theme-switch` adds Golden Gate After Dark (macOS default), soft/vivid Obsidian Glass, WezTerm and per-theme Starship handling.
- Modern Neovim sockets use `T/nvim.<user>/<random>/nvim.<pid>.0`; macOS switcher covers these alongside legacy paths and reloads the family loader for A/B switching.
- Neovim config is a separate local Git repo, not part of common deployment. Theme overlay adds files only; `profiles/macos/home/.config/nvim/after/plugin/obsidian-glass.lua` reads the current selection after init loads.
- Sketchybar palette loads dynamically through `profiles/macos/home/.config/sketchybar/colors.lua`; reload command does not start a stopped service.
- `profiles/macos/GOLDEN-GATE-AFTER-DARK.md`: default palette, unchanged native wallpaper, application/recovery. `profiles/macos/OBSIDIAN-GLASS.md`: alternate palettes/wallpapers.
- Herdr canonical override: `active_row_bg` controls active Space/focused Agent backgrounds; `surface_dim` does not. `selection_bg` is the Navigate-mode cursor. Golden Gate explicitly uses dark bay-blue to avoid the bright overlay0 fallback. Regression: `profiles/macos/tests/golden-gate-after-dark.sh`.
- `profiles/macos/tests/obsidian-glass.sh`: offline checks, isolated tmux socket, Herdr text/selection contrast guards.
- Herdr requires its own `profiles/macos/home/.config/herdr/themes/obsidian-glass.toml`; otherwise sidebar/tabs retain the previously selected theme. Profile config provides the default; macOS switcher splices the palette and reloads the running server.
- Wallpaper fallback gotcha: updating only `Configuration` preserves aerial providers. `profiles/macos/home/.local/bin/wallpaper-all-spaces:main()` replaces the complete choice with the image provider and clears provider-specific options. Regression: `profiles/macos/tests/test_wallpaper_all_spaces.py`.

Updated: 2026-10-08
