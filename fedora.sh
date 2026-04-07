#!/usr/bin/env bash

# Fedora GNOME desktop preferences
# Equivalent of osx.sh — configures GNOME settings via gsettings/dconf

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Set interface to Dark
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

# Set accent color (pink, close to the macOS highlight color)
gsettings set org.gnome.desktop.interface accent-color 'pink'

# Show weekday in clock
gsettings set org.gnome.desktop.interface clock-show-weekday true

# Show battery percentage
gsettings set org.gnome.desktop.interface show-battery-percentage true

# Disable hot corner (Activities)
gsettings set org.gnome.desktop.interface enable-hot-corners false

# Center new windows
gsettings set org.gnome.mutter center-new-windows true

# Disable event sounds
# gsettings set org.gnome.desktop.sound event-sounds false

###############################################################################
# Trackpad, mouse, keyboard, and input                                        #
###############################################################################

# Trackpad: enable tap to click
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true

# Trackpad: natural scrolling (disable for "traditional" scrolling)
# gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false

# Mouse: disable natural scrolling (for external mouse)
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false

# Set a blazingly fast keyboard repeat rate
gsettings set org.gnome.desktop.peripherals.keyboard repeat true
gsettings set org.gnome.desktop.peripherals.keyboard delay 250
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25

# Disable Caps Lock (remap to Ctrl or use kanata instead)
# gsettings set org.gnome.desktop.input-sources xkb-options "['caps:ctrl_modifier']"

# Set measurement to metric
# gsettings set org.gnome.system.locale region 'pt_BR.UTF-8'

###############################################################################
# Screen & power                                                              #
###############################################################################

# Require password immediately after sleep/screen lock
gsettings set org.gnome.desktop.screensaver lock-enabled true
gsettings set org.gnome.desktop.screensaver lock-delay 0

# Blank screen after 5 minutes of inactivity (300 seconds)
gsettings set org.gnome.desktop.session idle-delay 300

# Never suspend when plugged in
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

# Suspend after 30 minutes on battery
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800

# Power button action: interactive (show dialog)
# gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive'

# Enable fractional scaling (for HiDPI displays)
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"

# Font rendering
gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
gsettings set org.gnome.desktop.interface font-hinting 'slight'

###############################################################################
# Nautilus (file manager, equivalent to Finder)                               #
###############################################################################

# Default view: list view
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'

# Sort directories first
gsettings set org.gnome.nautilus.preferences default-sort-order 'name'
gsettings set org.gtk.Settings.FileChooser sort-directories-first true

# Show hidden files
# gsettings set org.gnome.nautilus.preferences show-hidden-files true

# Enable delete (not just trash)
# gsettings set org.gnome.nautilus.preferences show-delete-permanently true

###############################################################################
# Dock (GNOME Dash-to-Dock / Ubuntu Dock)                                    #
###############################################################################

# These settings work with the built-in GNOME dash or dash-to-dock extension
# If using Fedora's default GNOME (no dash-to-dock), these configure the dash

# Dash-to-dock settings (if extension is installed)
DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"
if gsettings list-schemas | grep -q "$DOCK_SCHEMA"; then
  # Set icon size to 36
  gsettings set $DOCK_SCHEMA dash-max-icon-size 36

  # Auto-hide the dock
  gsettings set $DOCK_SCHEMA dock-fixed false
  gsettings set $DOCK_SCHEMA autohide true
  gsettings set $DOCK_SCHEMA intellihide true

  # Remove auto-hide delay
  gsettings set $DOCK_SCHEMA autohide-in-fullscreen false
  gsettings set $DOCK_SCHEMA hide-delay 0.0
  gsettings set $DOCK_SCHEMA show-delay 0.0

  # Minimize on click
  gsettings set $DOCK_SCHEMA click-action 'minimize'

  # Show on all monitors
  gsettings set $DOCK_SCHEMA multi-monitor true

  # Don't show trash or mounted volumes in dock
  gsettings set $DOCK_SCHEMA show-trash false
  gsettings set $DOCK_SCHEMA show-mounts false
fi

###############################################################################
# Workspaces                                                                  #
###############################################################################

# Dynamic workspaces
gsettings set org.gnome.mutter dynamic-workspaces true

# Workspaces span all displays
gsettings set org.gnome.mutter workspaces-only-on-primary false

###############################################################################
# Window management — Forge (tiling extension)                                #
###############################################################################

# Install Forge GNOME extension if not present
FORGE_UUID="forge@jmmaranan.com"

if ! gnome-extensions list 2>/dev/null | grep -q "$FORGE_UUID"; then
  echo "• Installing Forge tiling extension"

  # Install extension manager dependencies
  sudo dnf install -y gnome-extensions-app gnome-shell-extension-common 2>/dev/null

  # Try installing via GNOME Extensions CLI
  if command -v gext &>/dev/null; then
    gext install forge@jmmaranan.com
  else
    echo "  - Install Forge manually: https://extensions.gnome.org/extension/4481/forge/"
    echo "    Or: sudo dnf install gnome-shell-extension-forge"
    sudo dnf install -y gnome-shell-extension-forge 2>/dev/null || true
  fi
fi

# Enable Forge
gnome-extensions enable "$FORGE_UUID" 2>/dev/null || true

# Configure Forge via dconf (if installed)
FORGE_DCONF="/org/gnome/shell/extensions/forge"
if dconf list "$FORGE_DCONF/" &>/dev/null 2>&1; then
  # Tabbed mode by default
  dconf write "$FORGE_DCONF/tabbed-tiling-mode-enabled" true

  # Window gaps
  dconf write "$FORGE_DCONF/window-gap-size" "uint32 4"
  dconf write "$FORGE_DCONF/window-gap-size-increment" "uint32 1"
  dconf write "$FORGE_DCONF/window-gap-hidden-on-single" true

  # Show focus hint border
  dconf write "$FORGE_DCONF/focus-border-toggle" true

  # Stacked tiling mode
  dconf write "$FORGE_DCONF/stacked-tiling-mode-enabled" true

  # Float utility/media apps (mirrors yabai manage=off rules from macOS)
  dconf write "$FORGE_DCONF/window-rules" "'[
    {\"wmclass\":\"gnome-control-center\",\"action\":\"float\"},
    {\"wmclass\":\"gnome-calculator\",\"action\":\"float\"},
    {\"wmclass\":\"gnome-system-monitor\",\"action\":\"float\"},
    {\"wmclass\":\"nautilus\",\"action\":\"float\"},
    {\"wmclass\":\"docker-desktop\",\"action\":\"float\"},
    {\"wmclass\":\"spotify\",\"action\":\"float\"},
    {\"wmclass\":\"loom\",\"action\":\"float\"},
    {\"wmclass\":\"whatsapp\",\"action\":\"float\"}
  ]'"

  echo "  - Forge configured"
fi

###############################################################################
# GNOME keyboard shortcuts                                                    #
###############################################################################

# Close window: Super+Q (like macOS Cmd+Q)
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"

# Custom keybindings
CUSTOM_KB_BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
CUSTOM_KB_0="${CUSTOM_KB_BASE}/custom0/"
CUSTOM_KB_1="${CUSTOM_KB_BASE}/custom1/"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['${CUSTOM_KB_0}', '${CUSTOM_KB_1}']"

# Launch terminal: Super+Return
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CUSTOM_KB_0} name "Launch Terminal"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CUSTOM_KB_0} command "ghostty"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CUSTOM_KB_0} binding "'<Super>Return'"

# Vicinae launcher: Alt+Space
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CUSTOM_KB_1} name "Vicinae Toggle"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CUSTOM_KB_1} command "vicinae toggle"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CUSTOM_KB_1} binding "'<Alt>space'"

# Switch workspaces: Alt+1..8
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Alt>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Alt>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Alt>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Alt>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Alt>5']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Alt>6']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Alt>7']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Alt>8']"

# Move window to workspace: Alt+Shift+1..8
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Alt><Shift>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Alt><Shift>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Alt><Shift>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Alt><Shift>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Alt><Shift>5']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Alt><Shift>6']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<Alt><Shift>7']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<Alt><Shift>8']"

# Toggle fullscreen: Super+F
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"

# Disable default shortcuts that conflict with Forge focus/move bindings
gsettings set org.gnome.shell.keybindings toggle-message-tray "[]"  # frees Super+M

# Disable default Super+num shortcuts (they conflict with workspace switching)
for i in 1 2 3 4 5 6 7 8 9; do
  gsettings set org.gnome.shell.keybindings "switch-to-application-$i" "[]"
done

###############################################################################
# Forge keybindings — window focus & move (Colemak-DH MNEI)                  #
###############################################################################

FORGE_KB="org.gnome.shell.extensions.forge.keybindings"
if gsettings list-schemas | grep -q "$FORGE_KB"; then
  # Focus: Super + MNEI
  gsettings set $FORGE_KB window-focus-left "['<Super>m']"
  gsettings set $FORGE_KB window-focus-down "['<Super>n']"
  gsettings set $FORGE_KB window-focus-up "['<Super>e']"
  gsettings set $FORGE_KB window-focus-right "['<Super>i']"

  # Move/swap: Super+Shift + MNEI (matches macOS cmd+shift)
  gsettings set $FORGE_KB window-swap-left "['<Super><Shift>m']"
  gsettings set $FORGE_KB window-swap-down "['<Super><Shift>n']"
  gsettings set $FORGE_KB window-swap-up "['<Super><Shift>e']"
  gsettings set $FORGE_KB window-swap-right "['<Super><Shift>i']"

  echo "  - Forge keybindings configured (focus/swap: Super+MNEI)"
fi

###############################################################################
# Privacy & search                                                            #
###############################################################################

# Disable file history tracking
gsettings set org.gnome.desktop.privacy remember-recent-files false

# Disable automatic problem reporting
gsettings set org.gnome.desktop.privacy report-technical-problems false

# Remove old temp files after 7 days
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy old-files-age 7

# Remove old trash files after 7 days
gsettings set org.gnome.desktop.privacy remove-old-trash-files true

###############################################################################
# Night Light (blue light filter)                                             #
###############################################################################

# Enable night light
# gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
# gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true
# gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500

###############################################################################
# Kill affected applications / reload                                         #
###############################################################################

echo "Done. Note that some of these changes require a logout/restart to take effect."
echo ""
echo "To apply Forge/extension changes, restart GNOME Shell:"
echo "  - Wayland: log out and log back in"
echo "  - X11: press Alt+F2, type 'r', press Enter"
