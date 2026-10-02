#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TEMP=$(mktemp -d)
trap 'rm -rf "$TEMP"' EXIT
export HOME="$TEMP/home"
mkdir -p "$HOME"
export DOTFILES_ROOT="$ROOT"
source "$ROOT/lib/deploy.sh"
source "$ROOT/profiles/fedora-gnome/install-runtimes.sh"
begin_deployment fedora-gnome

# No downloads or real runtime installation: exercise the actual helper flow.
mise() {
  printf '%s\n' "$*" >> "$TEMP/calls"
  case "$1" in
    env) printf 'export FEDORA_RUNTIME_TEST=activated\n' ;;
  esac
}
profile_install_runtimes
cmp "$ROOT/profiles/fedora-gnome/home/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
grep -Fxq "install --cd $HOME" "$TEMP/calls"
grep -Fxq "exec --cd $HOME -- npm install -g markdownlint-cli tree-sitter-cli" "$TEMP/calls"
[[ ${FEDORA_RUNTIME_TEST:-} == activated ]]

# Failures must stop before npm installation or environment activation.
mise() {
  printf '%s\n' "$*" >> "$TEMP/failures"
  [[ $1 != install ]]
}
if profile_install_runtimes; then
  echo 'Expected runtime installation failure' >&2
  exit 1
fi
[[ $(wc -l < "$TEMP/failures") == 1 ]]

bash -n "$ROOT/profiles/fedora-gnome/profile.sh" \
  "$ROOT/profiles/fedora-gnome/packages/formulae.sh" \
  "$ROOT/profiles/fedora-gnome/install-runtimes.sh"
zsh -n "$ROOT/home/common/.config/zsh/.zshrc" \
  "$ROOT/home/common/.config/zsh/.zsh_profile"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
import tomllib
root = Path(sys.argv[1])
config = tomllib.loads((root / 'profiles/fedora-gnome/home/.config/mise/config.toml').read_text())
assert config['tools'] == {'node': 'lts', 'bun': 'latest', 'lua': '5.4', 'pnpm': 'latest'}
profile = (root / 'profiles/fedora-gnome/profile.sh').read_text()
assert 'nvm' not in profile and 'lib/node.sh' not in profile
packages = (root / 'profiles/fedora-gnome/packages/formulae.sh').read_text()
assert 'bun.sh/install' not in packages and 'asdf-vm/asdf.git' not in packages
PY
printf 'Fedora runtime migration tests passed.\n'
