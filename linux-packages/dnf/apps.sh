#!/usr/bin/env bash

# Install GUI apps via Flatpak and dnf (mirrors brew/cask.sh)

echo "• Installing GUI apps via Flatpak and dnf"

# Ensure Flatpak and Flathub are set up
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

function installflatpak() {
  flatpak install -y flathub "${@}" 2>/dev/null
}

# Browsers
installflatpak com.google.Chrome
installflatpak app.zen_browser.zen

# Terminals
sudo dnf install -y \
  alacritty \
  kitty

# Wezterm (COPR)
if ! command -v wezterm &>/dev/null; then
  sudo dnf copr enable -y wezfurlong/wezterm-nightly 2>/dev/null && \
    sudo dnf install -y wezterm 2>/dev/null || \
    echo "  ⚠ wezterm: COPR not available, install manually from https://wezfurlong.org/wezterm/"
fi
if ! command -v ghostty &>/dev/null; then
  echo "  - Ghostty: install manually from https://ghostty.org/download or COPR"
fi

# Development
installflatpak com.google.AndroidStudio
installflatpak io.dbeaver.DBeaverCommunity
installflatpak com.getpostman.Postman
installflatpak com.mongodb.Compass

# Google Cloud CLI
if ! command -v gcloud &>/dev/null; then
  echo "  - gcloud: install from https://cloud.google.com/sdk/docs/install#rpm"
fi

# VS Code (RPM repo)
if ! command -v code &>/dev/null; then
  echo "  - Installing VS Code via RPM repo"
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
  sudo dnf install -y code
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
sudo dnf install -y texlive-scheme-basic 2>/dev/null || true

# Utilities
installflatpak com.github.tchx84.Flatseal
sudo dnf install -y flameshot

# Fonts — Nerd Fonts
echo "  - Installing Nerd Fonts"
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
NERD_FONTS=("JetBrainsMono" "Hack" "FantasqueSansMono")
for font in "${NERD_FONTS[@]}"; do
  if [ ! -d "$FONT_DIR/$font" ]; then
    echo "    - Installing $font Nerd Font"
    curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.tar.xz" -o "/tmp/${font}.tar.xz"
    mkdir -p "$FONT_DIR/$font"
    tar xf "/tmp/${font}.tar.xz" -C "$FONT_DIR/$font"
    rm "/tmp/${font}.tar.xz"
  else
    echo "    - $font Nerd Font already installed"
  fi
done
fc-cache -fv "$FONT_DIR" > /dev/null 2>&1

# Maple Mono font
if [ ! -d "$FONT_DIR/MapleMono" ]; then
  echo "    - Installing Maple Mono font"
  curl -sL "https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF.zip" -o "/tmp/MapleMono-NF.zip"
  mkdir -p "$FONT_DIR/MapleMono"
  unzip -qo "/tmp/MapleMono-NF.zip" -d "$FONT_DIR/MapleMono"
  rm "/tmp/MapleMono-NF.zip"
  fc-cache -fv "$FONT_DIR" > /dev/null 2>&1
fi

echo "  ✓ GUI apps installed"
