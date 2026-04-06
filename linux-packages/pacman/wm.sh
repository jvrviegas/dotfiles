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
  xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk \
  waybar

# Quickshell + Caelestia shell (bar, launcher, dashboard, notifications, lock screen)
if command -v paru &>/dev/null; then
  echo "  - Installing Quickshell + Caelestia via AUR"
  paru -S --noconfirm --needed quickshell-git caelestia-shell caelestia-cli
else
  echo "  - Quickshell/Caelestia: install from AUR (paru required)"
fi

# Caelestia dependencies
sudo pacman -S --noconfirm --needed \
  fish \
  lm_sensors \
  ddcutil \
  ttf-material-symbols-variable-git 2>/dev/null || true
if command -v paru &>/dev/null; then
  paru -S --noconfirm --needed cava-git 2>/dev/null || true
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
