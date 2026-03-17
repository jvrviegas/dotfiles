#!/usr/bin/env bash

# Window management stack (CachyOS / Arch)
# Hyprland + Quickshell + Vicinae

echo "• Installing window management stack"

# Hyprland compositor (CachyOS has optimized hyprland packages)
sudo pacman -S --noconfirm --needed hyprland

# Hyprland ecosystem
sudo pacman -S --noconfirm --needed \
  hyprpaper \
  hypridle \
  hyprlock \
  xdg-desktop-portal-hyprland

# Quickshell (bar/shell framework)
if ! command -v quickshell &>/dev/null; then
  if command -v paru &>/dev/null; then
    echo "  - Installing Quickshell via AUR"
    paru -S --noconfirm --needed quickshell-git
  else
    echo "  - Quickshell: install from https://quickshell.outfoxxed.me/docs/guide/installation"
  fi
fi

# Vicinae (Raycast-like launcher)
if ! command -v vicinae &>/dev/null; then
  if command -v paru &>/dev/null; then
    paru -S --noconfirm --needed vicinae-bin 2>/dev/null || \
      echo "  - Vicinae: install from https://github.com/vicinaehq/vicinae"
  else
    echo "  - Vicinae: install from https://github.com/vicinaehq/vicinae"
  fi
fi

# Supporting tools
sudo pacman -S --noconfirm --needed \
  pipewire \
  wireplumber \
  polkit-gnome \
  grim \
  slurp \
  wl-clipboard \
  brightnessctl \
  playerctl \
  networkmanager \
  nm-connection-editor \
  pavucontrol \
  blueman

echo "  ✓ Window management stack installed"
