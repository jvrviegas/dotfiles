#!/usr/bin/env bash

# Deploy the items selected in OMARCHY_CONFIG_CHECKLIST.md while preserving
# Omarchy-managed terminal, tmux, and theme configuration. Hyprland overrides
# are installed individually, and shell layout changes use the Omarchy CLI.

COMMON_HOME="$DOTFILES_ROOT/home/common"
PROFILE_HOME="$DOTFILES_ROOT/profiles/omarchy/home"

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

echo "• Deploying selected Zsh configuration"
deploy_file "$COMMON_HOME/.zshenv" "$HOME/.zshenv"
deploy_file "$COMMON_HOME/.config/zsh/.zshrc" "$HOME/.config/zsh/.zshrc"
deploy_file "$COMMON_HOME/.config/zsh/.zsh_profile" "$HOME/.config/zsh/.zsh_profile"
deploy_file "$COMMON_HOME/.config/zsh/zap_zsh.sh" "$HOME/.config/zsh/zap_zsh.sh" 755

# Use Omarchy's normal Starship path. Color names resolve through the terminal
# palette, so they continue following `omarchy theme set`.
deploy_file "$COMMON_HOME/.config/starship/starship.toml" "$HOME/.config/starship.toml"

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
backup_path "$git_config"
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
done < <(git config --file "$COMMON_HOME/.gitconfig" --null --list)

deploy_file "$COMMON_HOME/.config/git/ignore" "$HOME/.config/git/ignore"
echo "  - Preserved the existing Git name and email"
echo ""

echo "• Deploying Omarchy desktop customizations"
deploy_file "$PROFILE_HOME/.config/hypr/looknfeel.lua" "$HOME/.config/hypr/looknfeel.lua"
deploy_file "$PROFILE_HOME/.config/hypr/input.lua" "$HOME/.config/hypr/input.lua"
deploy_file "$PROFILE_HOME/.config/xkb/symbols/us_mac_accents" \
  "$HOME/.config/xkb/symbols/us_mac_accents"
deploy_file "$PROFILE_HOME/.XCompose" "$HOME/.XCompose"
deploy_file "$PROFILE_HOME/.config/omarchy/shell.toml" "$HOME/.config/omarchy/shell.toml"

# Port the custom macOS palettes to native Omarchy themes. Omarchy generates
# terminal, shell, Hyprland, tmux, Neovim, and application themes from each
# colors.toml; the shared wallpapers are installed as theme backgrounds.
custom_themes=(
  the-mandalorian
  the-witcher
  hollow-knight
  red-dead-redemption-2
  darth-vader
)
for theme in "${custom_themes[@]}"; do
  theme_source="$PROFILE_HOME/.config/omarchy/themes/$theme"
  theme_target="$HOME/.config/omarchy/themes/$theme"
  deploy_overlay "$theme_source" "$theme_target"

  wallpaper=$(find "$COMMON_HOME/.config/wallpapers" -maxdepth 1 -type f \
    -name "$theme.*" -print -quit)
  if [[ -n $wallpaper ]]; then
    deploy_file "$wallpaper" "$theme_target/backgrounds/$(basename "$wallpaper")"
  fi
done

xkbcli compile-keymap --test \
  --layout us_mac_accents \
  --variant intl \
  --options compose:caps,shift:both_capslock_cancel,lv3:lalt_switch,lv3:ralt_alt
omarchy restart xcompose

# Install the user-owned clock plugin. It follows Omarchy's built-in clock but
# anchors its calendar to the clock instead of centering it on the bar.
clock_plugin_id="joaoviegas.clock"
clock_plugin_source="$PROFILE_HOME/.config/omarchy/plugins/$clock_plugin_id"
clock_plugin_target="$HOME/.config/omarchy/plugins/$clock_plugin_id"
for plugin_file in BarWidget.qml Model.js Panel.qml manifest.json; do
  deploy_file "$clock_plugin_source/$plugin_file" "$clock_plugin_target/$plugin_file"
done
omarchy plugin validate "$clock_plugin_target"

# Install the user-owned bar plugin. This full-bar clone adds an inset floating
# surface with rounded corners; shell.toml controls its 38px content height.
bar_plugin_id="joaoviegas.bar"
bar_plugin_source="$PROFILE_HOME/.config/omarchy/plugins/$bar_plugin_id"
bar_plugin_target="$HOME/.config/omarchy/plugins/$bar_plugin_id"
deploy_overlay "$bar_plugin_source" "$bar_plugin_target"
omarchy plugin validate "$bar_plugin_target"
omarchy-shell shell rescanPlugins >/dev/null

# Keep the current shell layout intact while enabling the customized clock and
# selecting the floating bar implementation.
backup_path "$HOME/.config/omarchy/shell.json"
omarchy plugin enable "$clock_plugin_id" --section right --index 9999
omarchy plugin enable "$bar_plugin_id"
omarchy restart shell

if hyprctl reload &>/dev/null; then
  config_errors=$(hyprctl configerrors)
  if [[ -n $config_errors ]]; then
    echo "✗ Hyprland reported configuration errors:" >&2
    printf '%s\n' "$config_errors" >&2
    exit 1
  fi
  echo "  - Hyprland configuration reloaded successfully"
else
  echo "  ! Hyprland is not active; customizations will load at next login"
fi
echo ""

echo "• Configuring Syncthing"
if command -v syncthing &>/dev/null; then
  systemctl --user enable --now syncthing.service
  echo "  - Syncthing enabled and running"
  echo "  - Web UI: http://127.0.0.1:8384"
else
  echo "✗ Syncthing is not installed; run the profile without --config-only first." >&2
  exit 1
fi
echo ""

echo "• Deploying shared agent skills"
deploy_overlay "$DOTFILES_ROOT/agent-skills" "$HOME/.agents/skills"
echo "  - Installed shared skills in ~/.agents/skills"
echo ""

echo "• Deploying Herdr sessionizer"
deploy_file "$COMMON_HOME/.local/bin/herdr-sessionizer" "$HOME/.local/bin/herdr-sessionizer" 755
echo ""

echo "• Configuring Kanata with Colemak-DH"
kanata_tmp=$(mktemp)
rules_tmp=$(mktemp)
modules_tmp=$(mktemp)
trap 'rm -f "$kanata_tmp" "$rules_tmp" "$modules_tmp"' EXIT

configured_device=$(awk '$1 == "linux-dev" { print $2; exit }' \
  "$COMMON_HOME/.config/kanata/colemak_dhm.kbd")
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
  "$COMMON_HOME/.config/kanata/colemak_dhm.kbd" >"$kanata_tmp"
kanata --check --cfg "$kanata_tmp"
deploy_file "$kanata_tmp" "$HOME/.config/kanata/colemak_dhm.kbd"
echo "  - Kanata keyboard: $keyboard_device"

deploy_file "$PROFILE_HOME/.config/systemd/user/kanata.service" \
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

echo "✓ Selected Omarchy configuration is installed."
echo "  Start a new login session to use Zsh and any new group membership."
