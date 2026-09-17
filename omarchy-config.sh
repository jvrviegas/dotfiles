#!/usr/bin/env bash

# Deploy the items selected in OMARCHY_CONFIG_CHECKLIST.md without replacing
# Omarchy's Hyprland, shell, terminal, tmux, or theme-managed configuration.

set -Eeuo pipefail
trap 'status=$?; echo "✗ Configuration failed at line $LINENO: $BASH_COMMAND (exit $status)" >&2' ERR

if [[ $EUID -eq 0 ]]; then
  echo "✗ Run this script as your regular user, not as root." >&2
  exit 1
fi

if ! command -v omarchy &>/dev/null; then
  echo "✗ Omarchy was not detected on this system." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.local/state/dotfiles-backups/omarchy-$(date +%Y%m%d-%H%M%S)"
BACKUP_CREATED=false

run_as_root() {
  if [[ -t 0 && -t 1 ]]; then
    sudo "$@"
  elif sudo -n "$@" 2>/dev/null; then
    return 0
  elif command -v pkexec &>/dev/null; then
    pkexec "$@"
  else
    echo "✗ This step needs administrator access, but no terminal or pkexec is available." >&2
    return 1
  fi
}

backup_user_path() {
  local path=$1 relative
  [[ -e $path || -L $path ]] || return 0

  relative=${path#"$HOME"/}
  mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
  cp -a "$path" "$BACKUP_DIR/$relative"
  BACKUP_CREATED=true
}

install_user_file() {
  local source=$1 destination=$2 mode=${3:-644}

  if [[ -f $destination ]] && cmp -s "$source" "$destination"; then
    echo "  - Unchanged: ${destination/#$HOME/~}"
    return
  fi

  backup_user_path "$destination"
  install -Dm"$mode" "$source" "$destination"
  echo "  - Installed: ${destination/#$HOME/~}"
}

echo "• Installing Zsh and Kanata"
omarchy pkg add zsh
omarchy pkg aur add kanata-bin
echo ""

echo "• Deploying selected Zsh configuration"
install_user_file "$SCRIPT_DIR/.zshenv" "$HOME/.zshenv"
install_user_file "$SCRIPT_DIR/.config/zsh/.zshrc" "$HOME/.config/zsh/.zshrc"
install_user_file "$SCRIPT_DIR/.config/zsh/.zsh_profile" "$HOME/.config/zsh/.zsh_profile"
install_user_file "$SCRIPT_DIR/.config/zsh/zap_zsh.sh" "$HOME/.config/zsh/zap_zsh.sh" 755

# Use Omarchy's normal Starship path. Color names resolve through the terminal
# palette, so they continue following `omarchy theme set`.
install_user_file "$SCRIPT_DIR/.config/starship/starship.toml" "$HOME/.config/starship.toml"

if [[ ! -f ${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh ]]; then
  echo "  - Installing Zap"
  zsh <(curl -fsSL https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) \
    --branch release-v1 --keep
else
  echo "  - Zap is already installed"
fi

zsh -n "$HOME/.config/zsh/.zshrc"
zsh -n "$HOME/.config/zsh/.zsh_profile"

zsh_path=$(command -v zsh)
current_shell=$(getent passwd "$USER" | cut -d: -f7)
if [[ $current_shell != "$zsh_path" ]]; then
  echo "  - Changing the default shell to $zsh_path"
  run_as_root "$(command -v usermod)" --shell "$zsh_path" "$USER"
else
  echo "  - Zsh is already the default shell"
fi
echo ""

echo "• Merging portable Git configuration"
git_config="$HOME/.config/git/config"
mkdir -p "$(dirname "$git_config")"
backup_user_path "$git_config"
touch "$git_config"

# Preserve Omarchy's identity and repository workflow defaults while merging
# this repository's aliases, colors, diff/merge behavior, and other preferences.
while IFS= read -r -d '' entry; do
  key=${entry%%$'\n'*}
  value=${entry#*$'\n'}
  case "$key" in
    user.* | core.excludesfile) continue ;;
  esac
  git config --file "$git_config" --replace-all "$key" "$value"
done < <(git config --file "$SCRIPT_DIR/.gitconfig" --null --list)

install_user_file "$SCRIPT_DIR/.config/git/ignore" "$HOME/.config/git/ignore"
echo "  - Preserved the existing Git name and email"
echo ""

echo "• Deploying shared agent skills"
mkdir -p "$HOME/.agents/skills"
for skill_source in "$SCRIPT_DIR"/agent-skills/*; do
  [[ -d $skill_source ]] || continue
  skill_name=${skill_source##*/}
  skill_target="$HOME/.agents/skills/$skill_name"
  if [[ -d $skill_target ]] && ! diff -qr "$skill_source" "$skill_target" &>/dev/null; then
    backup_user_path "$skill_target"
  fi
  mkdir -p "$skill_target"
  cp -a "$skill_source/." "$skill_target/"
done
echo "  - Installed shared skills in ~/.agents/skills"
echo ""

echo "• Deploying Herdr sessionizer"
install_user_file "$SCRIPT_DIR/.local/bin/herdr-sessionizer" "$HOME/.local/bin/herdr-sessionizer" 755
echo ""

echo "• Configuring Kanata with Colemak-DH"
kanata_tmp=$(mktemp)
rules_tmp=$(mktemp)
modules_tmp=$(mktemp)
trap 'rm -f "$kanata_tmp" "$rules_tmp" "$modules_tmp"' EXIT

configured_device=$(awk '$1 == "linux-dev" { print $2; exit }' \
  "$SCRIPT_DIR/.config/kanata/colemak_dhm.kbd")
keyboard_device=${KANATA_KEYBOARD_DEVICE:-}

if [[ -z $keyboard_device && -n $configured_device && -e $configured_device ]]; then
  keyboard_device=$configured_device
fi

if [[ -z $keyboard_device ]]; then
  shopt -s nullglob
  platform_keyboards=(/dev/input/by-path/platform-*-event-kbd)
  all_keyboards=(/dev/input/by-path/*-event-kbd)
  shopt -u nullglob

  if (( ${#platform_keyboards[@]} == 1 )); then
    keyboard_device=${platform_keyboards[0]}
  elif (( ${#all_keyboards[@]} == 1 )); then
    keyboard_device=${all_keyboards[0]}
  else
    echo "✗ Could not select a unique keyboard for Kanata." >&2
    echo "  Available keyboards:" >&2
    kanata --list >&2 || true
    echo "  Re-run with KANATA_KEYBOARD_DEVICE=/dev/input/by-path/..." >&2
    exit 1
  fi
fi

if [[ ! -e $keyboard_device ]]; then
  echo "✗ Kanata keyboard device does not exist: $keyboard_device" >&2
  exit 1
fi

sed -E "s#^([[:space:]]*linux-dev[[:space:]]+)[^[:space:]]+#\\1$keyboard_device#" \
  "$SCRIPT_DIR/.config/kanata/colemak_dhm.kbd" >"$kanata_tmp"
kanata --check --cfg "$kanata_tmp"
install_user_file "$kanata_tmp" "$HOME/.config/kanata/colemak_dhm.kbd"
echo "  - Kanata keyboard: $keyboard_device"

install_user_file "$SCRIPT_DIR/omarchy/systemd/user/kanata.service" \
  "$HOME/.config/systemd/user/kanata.service"

run_as_root "$(command -v usermod)" -aG input "$USER"

printf '%s\n' 'KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"' >"$rules_tmp"
printf '%s\n' 'uinput' >"$modules_tmp"
run_as_root "$(command -v install)" -Dm644 "$rules_tmp" /etc/udev/rules.d/99-kanata-uinput.rules
run_as_root "$(command -v install)" -Dm644 "$modules_tmp" /etc/modules-load.d/kanata-uinput.conf
run_as_root "$(command -v udevadm)" control --reload-rules
run_as_root "$(command -v udevadm)" trigger
run_as_root "$(command -v modprobe)" uinput

systemctl --user daemon-reload
systemctl --user enable kanata.service
if id -nG | tr ' ' '\n' | grep -qx input; then
  systemctl --user restart kanata.service
  echo "  - Kanata service enabled and started"
else
  echo "  - Kanata service enabled"
  echo "  ! Log out and back in to activate input-group membership, then run:"
  echo "    systemctl --user start kanata.service"
fi
echo ""

if [[ $BACKUP_CREATED == true ]]; then
  echo "• Replaced files were backed up to: $BACKUP_DIR"
fi

echo "✓ Selected Omarchy configuration is installed."
echo "  Start a new login session to use Zsh and any new group membership."
