#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
config="$PWD/profiles/macos/home/.config"

bash -n profiles/macos/home/.local/bin/theme-switch
bash -n "$config/tmux/themes/obsidian-glass.sh"
find "$config/nvim" -name '*.lua' -exec luac -p {} \;
luac -p "$config/sketchybar/themes/obsidian-glass.lua"
python3 - <<'PY'
import pathlib, tomllib
root = pathlib.Path('profiles/macos/home/.config')
for area in ('alacritty', 'wezterm', 'starship', 'herdr'):
    for p in (root / area).rglob('*.toml'):
        tomllib.loads(p.read_text())
# Readability guard: text remains legible on the selected sidebar row.
custom = tomllib.loads((root / 'herdr/themes/obsidian-glass.toml').read_text())['theme']['custom']
def luminance(color):
    channels = [int(color[i:i+2], 16) / 255 for i in (1, 3, 5)]
    channels = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in channels]
    return sum(v * w for v, w in zip(channels, (0.2126, 0.7152, 0.0722)))
def contrast(a, b):
    high, low = sorted((luminance(a), luminance(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)
for role in ('text', 'accent'):
    assert contrast(custom[role], custom['selection_bg']) >= 4.5, role
assert contrast(custom['mauve'], custom['surface_dim']) >= 4.5, 'selected branch'
for role in ('overlay1', 'subtext0', 'red', 'green', 'yellow', 'blue', 'teal', 'mauve'):
    assert contrast(custom[role], custom['surface0']) >= 4.5, role
PY

nvim --headless -u NONE "+set rtp^=$config/nvim" \
  '+colorscheme obsidian-glass' \
  "+lua assert(vim.g.colors_name == 'obsidian-glass'); assert(vim.api.nvim_get_hl(0,{name='Normal'}).bg == 0x08090A); assert(vim.api.nvim_get_hl(0,{name='DiagnosticError'}).fg == 0xE68A8A); assert(require('lualine.themes.obsidian-glass').normal.a.bg == '#BACACD')" '+qa'

nvim --headless -u NONE "+set rtp^=$config/nvim" \
  '+luafile profiles/macos/tests/obsidian-nvim.lua' \
  '+luafile profiles/macos/tests/obsidian-nvim-vivid.lua' '+qa'

export OBSIDIAN_TEST_SOCKET="obsidian-validation-$$"
trap 'command tmux -L "$OBSIDIAN_TEST_SOCKET" kill-server 2>/dev/null || true' EXIT
command tmux -L "$OBSIDIAN_TEST_SOCKET" -f /dev/null new-session -d -s validate 'sleep 60'
tmux() { command tmux -L "$OBSIDIAN_TEST_SOCKET" "$@"; }
export -f tmux
bash "$config/tmux/themes/obsidian-glass.sh"
test "$(tmux show-option -gv status-bg)" = '#08090a'
test "$(tmux show-option -gv status-fg)" = '#bacacd'
echo 'Obsidian Glass: Lua, TOML, Neovim and isolated tmux checks passed.'
