#!/usr/bin/env bash

# Install GUI apps via pacman, paru (AUR) and Flatpak (CachyOS / Arch)
# Mirrors brew/cask.sh

echo "• Installing GUI apps"

# Ensure Flatpak and Flathub are set up
sudo pacman -S --noconfirm --needed flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

function installflatpak() {
  flatpak install -y flathub "${@}" 2>/dev/null
}

# Browsers
sudo pacman -S --noconfirm --needed chromium
if command -v paru &>/dev/null; then
  paru -S --noconfirm --needed zen-browser-bin 2>/dev/null || installflatpak app.zen_browser.zen
else
  installflatpak app.zen_browser.zen
fi

# Terminals
sudo pacman -S --noconfirm --needed \
  alacritty \
  kitty \
  wezterm
if command -v paru &>/dev/null; then
  paru -S --noconfirm --needed ghostty 2>/dev/null || echo "  - Ghostty: install manually from https://ghostty.org/download"
fi

# Development
installflatpak com.google.AndroidStudio
installflatpak io.dbeaver.DBeaverCommunity
installflatpak com.getpostman.Postman
installflatpak com.mongodb.Compass

# Google Cloud CLI
if command -v paru &>/dev/null; then
  paru -S --noconfirm --needed google-cloud-cli 2>/dev/null || true
fi

# VS Code
if ! command -v code &>/dev/null; then
  if command -v paru &>/dev/null; then
    echo "  - Installing VS Code via AUR"
    paru -S --noconfirm --needed visual-studio-code-bin
  else
    installflatpak com.visualstudio.code
  fi
else
  echo "  - VS Code already installed"
fi

# Containers
installflatpak io.podman_desktop.PodmanDesktop

# Communication & productivity
installflatpak com.slack.Slack
installflatpak com.todoist.Todoist

# Media
installflatpak com.spotify.Client

# Documents & writing
sudo pacman -S --noconfirm --needed texlive-basic 2>/dev/null || true

# Utilities
installflatpak com.github.tchx84.Flatseal
sudo pacman -S --noconfirm --needed flameshot

# Fonts — Nerd Fonts (available in CachyOS/Arch repos)
echo "  - Installing Nerd Fonts"
sudo pacman -S --noconfirm --needed ttf-jetbrains-mono-nerd 2>/dev/null || true
sudo pacman -S --noconfirm --needed ttf-hack-nerd 2>/dev/null || true
sudo pacman -S --noconfirm --needed ttf-fantasque-nerd 2>/dev/null || true

if command -v paru &>/dev/null; then
  paru -S --noconfirm --needed ttf-maple 2>/dev/null || true
fi

# Fallback: manual install if not in repos
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
NERD_FONTS=("JetBrainsMono" "Hack" "FantasqueSansMono")
for font in "${NERD_FONTS[@]}"; do
  if ! fc-list | grep -qi "$font Nerd"; then
    echo "    - Installing $font Nerd Font manually"
    curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.tar.xz" -o "/tmp/${font}.tar.xz"
    mkdir -p "$FONT_DIR/$font"
    tar xf "/tmp/${font}.tar.xz" -C "$FONT_DIR/$font"
    rm "/tmp/${font}.tar.xz"
  fi
done
fc-cache -fv "$FONT_DIR" > /dev/null 2>&1

echo "  ✓ GUI apps installed"
