#!/usr/bin/env bash

# Install CLI tools via dnf (mirrors brew/formulae.sh)

echo "• Updating dnf and installing CLI tools"
sudo dnf upgrade -y --refresh

# Core utilities
sudo dnf install -y \
  coreutils \
  openssh \
  git \
  gh

# Editors
sudo dnf install -y \
  vim-enhanced \
  neovim

# Shell & prompt
sudo dnf install -y \
  fzf \
  eza \
  tmux \
  zoxide

# Starship (not in Fedora repos by default)
if ! command -v starship &>/dev/null; then
  echo "  - Installing Starship via install script"
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "  - Starship already installed"
fi

# Search & navigation
sudo dnf install -y \
  fd-find \
  ripgrep

# Lua
sudo dnf install -y \
  lua \
  luajit \
  luarocks

# lua-language-server (install via release binary)
if ! command -v lua-language-server &>/dev/null; then
  echo "  - Installing lua-language-server"
  LLS_VERSION=$(curl -s https://api.github.com/repos/LuaLS/lua-language-server/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  LLS_DIR="$HOME/.local/lib/lua-language-server"
  mkdir -p "$LLS_DIR"
  curl -sL "https://github.com/LuaLS/lua-language-server/releases/download/${LLS_VERSION}/lua-language-server-${LLS_VERSION}-linux-x64.tar.gz" | tar xz -C "$LLS_DIR"
  ln -sf "$LLS_DIR/bin/lua-language-server" "$HOME/.local/bin/lua-language-server"
  echo "  - lua-language-server installed to $LLS_DIR"
else
  echo "  - lua-language-server already installed"
fi

# Languages & runtimes
sudo dnf install -y \
  dotnet-sdk-8.0 \
  java-21-openjdk-devel \
  rustup

rustup-init -y --no-modify-path 2>/dev/null || true
source "$HOME/.cargo/env" 2>/dev/null || true

# ASDF (git clone install)
if [ ! -d "$HOME/.asdf" ]; then
  echo "  - Installing asdf"
  git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.0
  echo "  - asdf installed"
else
  echo "  - asdf already installed"
fi

# Mobile development
sudo dnf install -y \
  android-tools \
  yarn

# scrcpy (not in default repos)
if ! command -v scrcpy &>/dev/null; then
  sudo dnf copr enable -y zeno/scrcpy 2>/dev/null && sudo dnf install -y scrcpy || \
    echo "  ⚠ scrcpy: install manually from https://github.com/Genymobile/scrcpy"
fi

# Containers
sudo dnf install -y docker-compose

# Data & databases
sudo dnf install -y \
  jq \
  sqlite

# Media & documents
sudo dnf install -y \
  ffmpeg \
  fmt \
  fontforge \
  libsixel-devel \
  mpv \
  ocrmypdf \
  pandoc \
  poppler-utils \
  tesseract-langpack-eng

# Networking & security
sudo dnf install -y \
  httpie \
  nmap \
  pgpdump

# Build dependencies for cargo crates
sudo dnf install -y openssl-devel pkg-config

# websocat (install via cargo)
if ! command -v websocat &>/dev/null; then
  echo "  - Installing websocat via cargo"
  cargo install websocat
else
  echo "  - websocat already installed"
fi

# Keyboard
if ! command -v kanata &>/dev/null; then
  echo "  - Installing kanata via cargo"
  cargo install kanata
else
  echo "  - kanata already installed"
fi

# Virtualization (QEMU/KVM)
sudo dnf group install -y --with-optional virtualization
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt "$USER" 2>/dev/null || true

# Quickemu (easy VM management + ISO downloads)
# Usage:
#   quickget windows 11          # downloads Windows 11 ISO + VirtIO drivers
#   quickemu --vm windows-11.conf  # boots the VM
#   quickget list                 # shows all available OSes
#   quickgui                      # GUI frontend
if ! command -v quickemu &>/dev/null; then
  sudo dnf copr enable -y quickemu/quickemu 2>/dev/null && \
    sudo dnf install -y quickemu quickgui 2>/dev/null || \
    echo "  ⚠ quickemu: COPR not available for this Fedora version, install manually"
fi

# AI
curl -fsSL https://claude.ai/install.sh | bash

# System info
sudo dnf install -y fastfetch

echo "  ✓ CLI tools installed"
