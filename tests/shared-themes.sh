#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n home/common/.local/bin/theme-switch
bash -n profiles/fedora-gnome/home/.config/gnome/apply-openbar-theme.sh
python3 - <<'PY'
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib

root = Path.cwd()
themes = ('golden-gate-after-dark', 'obsidian-glass', 'obsidian-glass-vivid')
with tempfile.TemporaryDirectory() as tmp:
    home = Path(tmp)
    shutil.copytree(root / 'home/common/.config', home / '.config', symlinks=True)
    helper = home / '.config/gnome/apply-openbar-theme.sh'
    helper.parent.mkdir()
    shutil.copy2(root / 'profiles/fedora-gnome/home/.config/gnome/apply-openbar-theme.sh', helper)
    # Exercise the GNOME path without changing the real desktop or running apps.
    (home / '.local/share/gnome-shell/extensions/openbar@neuromorph').mkdir(parents=True)
    bin_dir = home / 'bin'
    bin_dir.mkdir()
    for name in ('tmux', 'nvim', 'herdr', 'gsettings', 'dconf'):
        mock = bin_dir / name
        mock.write_text('#!/bin/sh\nexit 0\n')
        mock.chmod(0o755)
    env = dict(os.environ, HOME=str(home), XDG_CURRENT_DESKTOP='GNOME',
               PATH=f'{bin_dir}:{os.environ["PATH"]}')
    for theme in themes:
        for area in ('alacritty', 'wezterm', 'starship', 'herdr'):
            path = home / f'.config/{area}/themes/{theme}.toml'
            tomllib.loads(path.read_text())
        assert (home / f'.config/nvim/colors/{theme}.lua').is_file()
        assert (home / f'.config/nvim/lua/lualine/themes/{theme}.lua').is_file()
        assert any((home / f'.config/wallpapers/{theme}.{ext}').is_file()
                   for ext in ('jpg', 'png'))
        subprocess.run(['bash', str(root / 'home/common/.local/bin/theme-switch'), theme],
                       env=env, check=True)
        assert (home / '.config/theme/current').read_text().strip() == theme
        assert f'theme = {theme}' in (home / '.config/ghostty/config').read_text()
        assert f'include themes/{theme}.conf' in (home / '.config/kitty/kitty.conf').read_text()
        assert (home / '.config/starship/starship.toml').read_bytes() == (
            home / f'.config/starship/themes/{theme}.toml').read_bytes()
print('Shared themes: isolated switching and GNOME helper checks passed.')
PY
