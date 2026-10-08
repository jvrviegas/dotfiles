# Obsidian Glass

macOS-only theme inspired by the three downloaded black-glass images.
Graphite backgrounds, silver focus indicators, restrained semantic colours.
All managed files live in `profiles/macos/home/`; Linux profiles are unchanged.

Readability tuning preserves the backgrounds and silver UI accent. Terminal
colours remain restrained; Neovim uses stronger semantic separation: purple
keywords, blue functions/directories, amber types/headings, sage strings,
peach numbers and teal parameters/inline code. Variables/prose stay near-white.
Markdown code blocks use a graphite surface rather than a blanket green tint.
Neo-tree selection and Git states have explicit colours; links are underlined.
Herdr has a matching sidebar/tab palette instead of inheriting Witcher colours.
Its primary selected text and selected branch colours are contrast-tested.

## Apply

```sh
./install --profile macos --config-only
~/.local/bin/theme-switch obsidian-glass
```

The macOS installer defaults to Golden Gate After Dark; select this theme with
`theme-switch obsidian-glass`. Reload Ghostty with
**Cmd+Shift+,**; open a new shell and restart existing Neovim instances.
Sketchybar uses the palette when running (the switcher reloads an existing
instance, but does not start the service). New tmux servers load the theme.

Neovim's separate repository retains its original `init.lua`. The profile adds
a colourscheme, a lualine palette and an `after/plugin/` loader that reads
`~/.config/theme/current`. That loader supports both Obsidian Glass variants and Golden Gate After Dark.

## Vivid variant (A/B comparison)

`obsidian-glass-vivid` keeps the same backgrounds and wallpaper but uses a
conventional, more saturated palette: blue `#61AFEF`, green `#98C379`, purple
`#C678DD`, amber `#E5C07B`, red `#E06C75`, cyan `#56B6C2`.
Its prompt uses an amber username and blue directory. Terminal, Neovim/lualine,
Herdr, tmux and Sketchybar palettes are included.

```sh
theme-switch obsidian-glass-vivid  # stronger colours
theme-switch obsidian-glass        # quieter original
```

Reload Ghostty with **Cmd+Shift+,** after switching. Starship updates at the
next prompt; running Neovim instances with discoverable sockets and Herdr are
reloaded by the switcher. The installer defaults to Golden Gate After Dark.

## Wallpapers

Default: `~/.config/wallpapers/obsidian-glass.jpg` (dark flowing glass).
Alternatives:

```sh
wallpaper-all-spaces ~/.config/wallpapers/obsidian-glass/reflective-glass.png
wallpaper-all-spaces ~/.config/wallpapers/obsidian-glass/silver-ribbons.jpg
```

Selecting the theme again restores the default wallpaper.

## Validation and recovery

Run `bash profiles/macos/tests/obsidian-glass.sh`.
After deployment, `ghostty +validate-config` checks the installed Ghostty theme.
The installer prints the backup directory under
`~/.local/state/dotfiles-backups/`. Restore specific prior files from that
directory to undo configuration changes; remove the newly added Neovim
overlay files to return to its original startup theme.
