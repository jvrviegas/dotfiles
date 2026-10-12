# Golden Gate After Dark

Default macOS theme: midnight/slate backgrounds, fog-white text, bridge-orange
focus accents, and distinct blue, sage, purple, amber and cyan syntax colours.
Managed entirely in `profiles/macos/home/`; Linux profiles are unchanged.

## Apply and switch

```sh
./install --profile macos --config-only
theme-switch golden-gate-after-dark
```

Includes Ghostty, Kitty, Alacritty, WezTerm, Neovim/lualine, Starship, tmux,
Herdr and Sketchybar. Reload Ghostty with **Cmd+Shift+,** after switching;
Starship updates on the next prompt. The switcher reloads running Herdr and
Neovim instances with discoverable sockets. Sketchybar must already be running.

Alternatives remain available:

```sh
theme-switch obsidian-glass
theme-switch obsidian-glass-vivid
```

Re-running the macOS installer selects Golden Gate After Dark again.
Neovim's separate `init.lua` is untouched; the profile adds colourscheme files
and an `after/plugin/obsidian-glass.lua` loader supporting all three themes.
Neovim editor, gutters, floating windows, completion menu, Telescope and Neo-tree
surfaces are transparent, inheriting the terminal background/opacity. Selection,
search, cursor-line, diff and statusline backgrounds remain for readability.

## Wallpaper

The supplied `Golden_Dark_6k.png` is bundled at
`profiles/macos/home/.config/wallpapers/golden-gate-after-dark.png` and deployed
to `~/.config/wallpapers/golden-gate-after-dark.png`. Selecting the theme applies
it across Mission Control spaces through `wallpaper-all-spaces`. The original
6016 × 4147 PNG is preserved; the Downloads copy is no longer required.

## Herdr selection

`theme.custom.active_row_bg = "#2D4050"` gives active Space and focused Agent rows
a dark bay-blue background. `selection_bg` separately controls the Navigate-mode
cursor row. `surface_dim` is not the active-row override.

The active row preserves title, branch and status colours with measured opaque
contrast ratios of 8.61:1, 4.59:1 and 5.25:1 respectively. These check readability,
not medical claims about visual fatigue.

## Validate

```sh
bash profiles/macos/tests/golden-gate-after-dark.sh
bash profiles/macos/tests/obsidian-glass.sh
python3 profiles/macos/tests/test_wallpaper_all_spaces.py
```

After installation, run `ghostty +validate-config` and `herdr config check`.
Replaced files are backed up under `~/.local/state/dotfiles-backups/`.
