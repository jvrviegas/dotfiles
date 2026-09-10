#!/usr/bin/env bash

# Portable GNOME configuration shared by dnf- and pacman-based systems.
# Package-manager-specific dependencies are installed before this file is sourced.

GNOME_CONFIG_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/.config/gnome"
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"

if [[ "${XDG_CURRENT_DESKTOP:-}" != *GNOME* ]] && ! command -v gnome-shell &>/dev/null; then
  echo "  ✗ GNOME Shell is not installed; skipping GNOME configuration"
  return 0 2>/dev/null || exit 0
fi

echo "• Configuring GNOME desktop"

###############################################################################
# General UI, input, power, files, and privacy                                #
###############################################################################

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface accent-color 'slate'
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.interface enable-hot-corners true
gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
gsettings set org.gnome.desktop.interface font-hinting 'slight'

gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
gsettings set org.gnome.desktop.peripherals.mouse speed -0.44855967078189296
gsettings set org.gnome.desktop.peripherals.keyboard repeat true
gsettings set org.gnome.desktop.peripherals.keyboard delay 250
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25
gsettings set org.gnome.desktop.input-sources xkb-options "['lv3:ralt_alt']"

gsettings set org.gnome.desktop.screensaver lock-enabled true
gsettings set org.gnome.desktop.screensaver lock-delay 0
gsettings set org.gnome.desktop.session idle-delay 300
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800

gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.mutter edge-tiling false
gsettings set org.gnome.mutter workspaces-only-on-primary true
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
gsettings set org.gnome.desktop.wm.preferences num-workspaces 8
gsettings set org.gnome.desktop.wm.preferences button-layout "'close,minimize,maximize:'"

gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
gsettings set org.gnome.nautilus.preferences default-sort-order 'name'
gsettings set org.gtk.Settings.FileChooser sort-directories-first true

gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.desktop.privacy report-technical-problems false
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy old-files-age 7
gsettings set org.gnome.desktop.privacy remove-old-trash-files true

###############################################################################
# WhiteSur theme and wallpaper                                                #
###############################################################################

install_theme_repo() {
  local repo="$1"
  shift
  local checkout
  checkout=$(mktemp -d)
  if git clone --depth 1 "$repo" "$checkout" >/dev/null 2>&1; then
    (cd "$checkout" && ./install.sh "$@") || echo "  ⚠ Theme installation failed: $repo"
  else
    echo "  ⚠ Could not download theme: $repo"
  fi
  rm -rf "$checkout"
}

if [[ ! -d "$HOME/.themes/WhiteSur-Dark-solid-blue" ]]; then
  echo "  - Installing WhiteSur GTK theme"
  install_theme_repo https://github.com/vinceliuice/WhiteSur-gtk-theme.git \
    -d "$HOME/.themes" -c dark -t blue -o solid
fi
if [[ ! -d "$HOME/.local/share/icons/WhiteSur-dark" ]]; then
  echo "  - Installing WhiteSur icon theme"
  install_theme_repo https://github.com/vinceliuice/WhiteSur-icon-theme.git \
    -d "$HOME/.local/share/icons"
fi

if [[ -d "$HOME/.themes/WhiteSur-Dark-solid-blue" ]]; then
  gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark-solid-blue'
  gsettings set org.gnome.desktop.wm.preferences theme 'WhiteSur-Dark-solid-blue'
fi
if [[ -d "$HOME/.local/share/icons/WhiteSur-dark" ]]; then
  gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
fi

WALLPAPER="$HOME/.config/wallpapers/the-witcher.jpg"
if [[ -f "$WALLPAPER" ]]; then
  WALLPAPER_URI="file://$WALLPAPER"
  gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER_URI"
  gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER_URI"
fi

###############################################################################
# Extensions                                                                  #
###############################################################################

mkdir -p "$EXTENSIONS_DIR"
if ! command -v gext &>/dev/null; then
  pipx install gnome-extensions-cli || true
  export PATH="$HOME/.local/bin:$PATH"
fi

# extensions.gnome.org IDs and UUIDs. gext selects a GNOME-compatible release.
GNOME_EXTENSIONS=(
  "4481:forge@jmmaranan.com"
  "1460:Vitals@CoreCoding.com"
  "307:dash-to-dock@micxgx.gmail.com"
  "3193:blur-my-shell@aunetx"
  "3843:just-perfection-desktop@just-perfection"
  "5177:vertical-workspaces@G-dH.github.com"
  "19:user-theme@gnome-shell-extensions.gcampax.github.com"
  "1319:gsconnect@andyholmes.github.io"
)

if command -v gext &>/dev/null; then
  for extension in "${GNOME_EXTENSIONS[@]}"; do
    extension_id="${extension%%:*}"
    extension_uuid="${extension#*:}"
    if ! gnome-extensions list 2>/dev/null | grep -Fxq "$extension_uuid"; then
      echo "  - Installing GNOME extension: $extension_uuid"
      gext install "$extension_id" || echo "  ⚠ Could not install $extension_uuid"
    fi
  done
else
  echo "  ⚠ gext is unavailable; extensions.gnome.org extensions were skipped"
fi

install_git_extension() {
  local repo="$1"
  local uuid="$2"
  shift 2
  [[ -d "$EXTENSIONS_DIR/$uuid" ]] && return

  local checkout
  checkout=$(mktemp -d)
  echo "  - Installing GNOME extension: $uuid"
  if git clone --depth 1 "$repo" "$checkout" >/dev/null 2>&1; then
    (cd "$checkout" && ./install.sh "$@") || echo "  ⚠ Could not install $uuid"
  else
    echo "  ⚠ Could not download $repo"
  fi
  rm -rf "$checkout"
}

# These two extensions are not distributed through extensions.gnome.org.
install_git_extension https://github.com/Anoryth/earport.git \
  earport@anoryth.github.io
install_git_extension https://github.com/HansRobo/coding-agent-rate-limit-indicator.git \
  coding-agent-rate-limit-indicator@github.com

# GNOME on Wayland may not notice a newly installed extension until the next
# login. Persist UUIDs now so each extension activates after that reload.
GNOME_EXTENSION_UUIDS=(
  "forge@jmmaranan.com"
  "Vitals@CoreCoding.com"
  "dash-to-dock@micxgx.gmail.com"
  "blur-my-shell@aunetx"
  "just-perfection-desktop@just-perfection"
  "vertical-workspaces@G-dH.github.com"
  "user-theme@gnome-shell-extensions.gcampax.github.com"
  "gsconnect@andyholmes.github.io"
  "earport@anoryth.github.io"
  "coding-agent-rate-limit-indicator@github.com"
  "vicinae@dagimg-dot"
)

python3 - "${GNOME_EXTENSION_UUIDS[@]}" <<'PYEOF' || true
import ast
import os
import subprocess
import sys

key = ["org.gnome.shell", "enabled-extensions"]
current = ast.literal_eval(subprocess.check_output(["gsettings", "get", *key], text=True).strip())
for uuid in sys.argv[1:]:
    path = os.path.expanduser(f"~/.local/share/gnome-shell/extensions/{uuid}")
    system_path = f"/usr/share/gnome-shell/extensions/{uuid}"
    if (os.path.isdir(path) or os.path.isdir(system_path)) and uuid not in current:
        current.append(uuid)
subprocess.run(["gsettings", "set", *key, str(current)], check=True)
PYEOF

# Restore sanitized extension preferences. The dumps deliberately exclude
# GSConnect device identities/certificates and the coding indicator's accounts.
declare -A EXTENSION_DCONF_PATHS=(
  [blur-my-shell]="/org/gnome/shell/extensions/blur-my-shell/"
  [dash-to-dock]="/org/gnome/shell/extensions/dash-to-dock/"
  [forge]="/org/gnome/shell/extensions/forge/"
  [just-perfection]="/org/gnome/shell/extensions/just-perfection/"
  [vertical-workspaces]="/org/gnome/shell/extensions/vertical-workspaces/"
  [vitals]="/org/gnome/shell/extensions/vitals/"
)
for extension_name in "${!EXTENSION_DCONF_PATHS[@]}"; do
  dump="$GNOME_CONFIG_DIR/extensions/$extension_name.dconf"
  [[ -f "$dump" ]] && dconf load "${EXTENSION_DCONF_PATHS[$extension_name]}" < "$dump"
done

# Small extension settings that do not warrant separate dumps.
dconf write /org/gnome/shell/extensions/user-theme/name "'WhiteSur-Dark-solid-blue'"
dconf write /org/gnome/shell/extensions/vicinae/show-status-indicator true
dconf write /org/gnome/shell/extensions/coding-agent-rate-limit-indicator/display-mode "'both'"
dconf write /org/gnome/shell/extensions/coding-agent-rate-limit-indicator/icon-style "'monochrome'"
dconf write /org/gnome/shell/extensions/coding-agent-rate-limit-indicator/panel-time-display-mode "'remaining'"
dconf write /org/gnome/shell/extensions/coding-agent-rate-limit-indicator/panel-window-mode "'primary'"
dconf write /org/gnome/shell/extensions/coding-agent-rate-limit-indicator/refresh-interval 900

###############################################################################
# Keyboard shortcuts and favorites                                            #
###############################################################################

gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"

CUSTOM_KB_BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
CUSTOM_KB_0="${CUSTOM_KB_BASE}/custom0/"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['${CUSTOM_KB_0}']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CUSTOM_KB_0} name 'Launch Terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CUSTOM_KB_0} command 'ghostty'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CUSTOM_KB_0} binding "'<Super>Return'"
# Vicinae owns Alt+Space through its input server; remove the obsolete shortcut.
dconf reset -f "${CUSTOM_KB_BASE}/custom1/" 2>/dev/null || true

for i in {1..8}; do
  gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$i" "['<Alt>$i']"
  gsettings set org.gnome.desktop.wm.keybindings "move-to-workspace-$i" "['<Alt><Shift>$i']"
done
gsettings set org.gnome.shell.keybindings toggle-message-tray "[]"
for i in {1..9}; do
  gsettings set org.gnome.shell.keybindings "switch-to-application-$i" "[]"
done

# Missing applications are harmless and appear once their desktop files exist.
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'com.google.Chrome.desktop', 'com.mitchellh.ghostty.desktop', 'com.slack.Slack.desktop', 'com.anthropic.Claude.desktop', 'app.zen_browser.zen.desktop']"

###############################################################################
# Vicinae                                                                     #
###############################################################################

VICINAE_EXT_UUID="vicinae@dagimg-dot"
if command -v vicinae &>/dev/null; then
  systemctl --user enable --now vicinae.service 2>/dev/null || true
  if [[ ! -d "$EXTENSIONS_DIR/$VICINAE_EXT_UUID" ]]; then
    VICINAE_EXT_TAG=$(curl -sSL https://api.github.com/repos/vicinaehq/gnome-extension/releases/latest \
      | grep -m1 '"tag_name"' | cut -d'"' -f4)
    if [[ -n "$VICINAE_EXT_TAG" ]]; then
      VICINAE_EXT_ZIP=$(mktemp --suffix=.zip)
      curl -sSLf -o "$VICINAE_EXT_ZIP" \
        "https://github.com/vicinaehq/gnome-extension/releases/download/${VICINAE_EXT_TAG}/vicinae%40dagimg-dot.shell-extension-${VICINAE_EXT_TAG}.zip" \
        && gnome-extensions install --force "$VICINAE_EXT_ZIP" \
        || echo "  ⚠ Could not install the Vicinae GNOME extension"
      rm -f "$VICINAE_EXT_ZIP"
    fi
  fi

  if [[ -d "$EXTENSIONS_DIR/$VICINAE_EXT_UUID" ]] \
    && ! gsettings get org.gnome.shell enabled-extensions | grep -Fq "$VICINAE_EXT_UUID"; then
    python3 - "$VICINAE_EXT_UUID" <<'PYEOF' || true
import ast
import subprocess
import sys

key = ["org.gnome.shell", "enabled-extensions"]
current = ast.literal_eval(subprocess.check_output(["gsettings", "get", *key], text=True).strip())
if sys.argv[1] not in current:
    current.append(sys.argv[1])
subprocess.run(["gsettings", "set", *key, str(current)], check=True)
PYEOF
  fi
fi

echo "  ✓ GNOME preferences and extensions configured"
echo "  - Log out and back in to load newly installed extensions"
