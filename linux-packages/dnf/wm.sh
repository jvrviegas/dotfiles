#!/usr/bin/env bash

# Window management stack (mirrors brew/wm.sh)
# Hyprland + Quickshell + Vicinae

echo "• Installing window management stack"

# Hyprland compositor + ecosystem
# Not in the Fedora repos (only the hypr* libraries are) — use the solopasha COPR
if ! dnf repoquery -q --qf '%{name}\n' hyprland 2>/dev/null | grep -qx hyprland; then
  echo "  - Enabling solopasha/hyprland COPR"
  sudo dnf copr enable -y solopasha/hyprland 2>/dev/null || \
    echo "  ⚠ hyprland COPR unavailable, install manually from https://wiki.hypr.land/"
fi

sudo dnf install -y --skip-unavailable \
  hyprland \
  hyprpaper \
  hypridle \
  hyprlock \
  xdg-desktop-portal-hyprland

# Quickshell (bar/shell framework) — in the Fedora repos since F42
sudo dnf install -y --skip-unavailable quickshell

# Vicinae (Raycast-like launcher)
if ! command -v vicinae &>/dev/null; then
  echo "  - Vicinae: install from https://github.com/vicinaehq/vicinae"
fi

# Supporting tools
sudo dnf install -y --skip-unavailable \
  pipewire \
  wireplumber \
  mate-polkit \
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
