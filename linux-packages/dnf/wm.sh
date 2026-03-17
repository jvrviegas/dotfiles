#!/usr/bin/env bash

# Window management stack (mirrors brew/wm.sh)
# Hyprland + Quickshell + Vicinae

echo "• Installing window management stack"

# Hyprland compositor
sudo dnf install -y hyprland

# Hyprland ecosystem
sudo dnf install -y \
  hyprpaper \
  hypridle \
  hyprlock \
  xdg-desktop-portal-hyprland

# Quickshell (bar/shell framework)
# Not yet in Fedora repos — install from COPR or source
if ! command -v quickshell &>/dev/null; then
  echo "  - Quickshell: install from https://quickshell.outfoxxed.me/docs/guide/installation"
  echo "    COPR: sudo dnf copr enable outfoxxed/quickshell && sudo dnf install -y quickshell"
fi

# Vicinae (Raycast-like launcher)
if ! command -v vicinae &>/dev/null; then
  echo "  - Vicinae: install from https://github.com/vicinaehq/vicinae"
fi

# Supporting tools
sudo dnf install -y \
  pipewire \
  wireplumber \
  polkit-gnome \
  grim \
  slurp \
  wl-clipboard \
  brightnessctl \
  playerctl \
  NetworkManager \
  nm-connection-editor \
  pavucontrol \
  blueman

echo "  ✓ Window management stack installed"
