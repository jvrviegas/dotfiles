#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
config="$PWD/profiles/macos/home/.config"

bash -n profiles/macos/home/.local/bin/theme-switch
bash -n "$config/tmux/themes/golden-gate-after-dark.sh"
luac -p "$config/nvim/colors/golden-gate-after-dark.lua"
luac -p "$config/nvim/lua/lualine/themes/golden-gate-after-dark.lua"
luac -p "$config/sketchybar/themes/golden-gate-after-dark.lua"
python3 - <<'PY'
from pathlib import Path
import tomllib
root = Path('profiles/macos/home/.config')
for area in ('alacritty', 'wezterm', 'starship', 'herdr'):
    for p in (root / area).rglob('*.toml'):
        tomllib.loads(p.read_text())
selected = tomllib.loads((root / 'herdr/config.toml').read_text())['theme']['custom']
theme = tomllib.loads((root / 'herdr/themes/golden-gate-after-dark.toml').read_text())['theme']['custom']
assert selected == theme
# Regression: surface_dim alone does not control active sidebar rows.
assert theme['active_row_bg'] == '#2D4050'
assert theme['overlay0'] == '#7D8F9D'
def luminance(color):
    channels = [int(color[i:i+2], 16) / 255 for i in (1, 3, 5)]
    channels = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in channels]
    return sum(v * w for v, w in zip(channels, (0.2126, 0.7152, 0.0722)))
for role in ('text', 'mauve', 'green'):
    high, low = sorted((luminance(theme[role]), luminance(theme['active_row_bg'])), reverse=True)
    assert (high + 0.05) / (low + 0.05) >= 4.5, role
wallpaper = root / 'wallpapers/golden-gate-after-dark.png'
with wallpaper.open('rb') as image:
    assert image.read(8) == b'\x89PNG\r\n\x1a\n'
assert (root / 'theme/current').read_text().strip() == 'golden-gate-after-dark'
assert 'theme = golden-gate-after-dark' in (root / 'ghostty/config').read_text()
assert (root / 'starship/starship.toml').read_text() == (root / 'starship/themes/golden-gate-after-dark.toml').read_text()
PY
nvim --headless -u NONE "+set rtp^=$config/nvim" \
  "+luafile profiles/macos/tests/golden-gate-nvim.lua" '+qa'

export GOLDEN_GATE_TEST_SOCKET="golden-gate-validation-$$"
trap 'command tmux -L "$GOLDEN_GATE_TEST_SOCKET" kill-server 2>/dev/null || true' EXIT
command tmux -L "$GOLDEN_GATE_TEST_SOCKET" -f /dev/null new-session -d -s validate 'sleep 60'
tmux() { command tmux -L "$GOLDEN_GATE_TEST_SOCKET" "$@"; }
export -f tmux
bash "$config/tmux/themes/golden-gate-after-dark.sh"
test "$(tmux show-option -gv status-bg)" = '#101820'
test "$(tmux show-option -gv status-fg)" = '#e58b65'
echo 'Golden Gate After Dark: defaults, palettes, sidebar contrast and tmux checks passed.'
