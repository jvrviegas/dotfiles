#!/usr/bin/env bash

# Install CLI tools via pacman (CachyOS / Arch)
# Mirrors brew/formulae.sh

echo "• Updating pacman and installing CLI tools"
sudo pacman -Syu --noconfirm

# Core utilities
sudo pacman -S --noconfirm --needed \
  coreutils \
  openssh \
  git \
  github-cli

# Editors
sudo pacman -S --noconfirm --needed \
  vim \
  neovim

# Shell & prompt
sudo pacman -S --noconfirm --needed \
  fzf \
  eza \
  starship \
  tmux \
  zoxide

# Search & navigation
sudo pacman -S --noconfirm --needed \
  fd \
  ripgrep

# Lua
sudo pacman -S --noconfirm --needed \
  lua \
  lua-language-server \
  luajit \
  luarocks

# Languages & runtimes
sudo pacman -S --noconfirm --needed \
  dotnet-sdk \
  jdk17-openjdk \
  rustup

rustup default stable 2>/dev/null || true

# ASDF (git clone install)
if [ ! -d "$HOME/.asdf" ]; then
  echo "  - Installing asdf"
  git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.0
  echo "  - asdf installed"
else
  echo "  - asdf already installed"
fi

# Mobile development
sudo pacman -S --noconfirm --needed \
  scrcpy \
  android-tools \
  yarn

if command -v paru &>/dev/null; then
  paru -S --noconfirm --needed watchman-bin 2>/dev/null || true
fi

# Containers
sudo pacman -S --noconfirm --needed docker-compose

# Data & databases
sudo pacman -S --noconfirm --needed \
  jq \
  sqlite

# Media & documents
sudo pacman -S --noconfirm --needed \
  ffmpeg \
  fmt \
  fontforge \
  libsixel \
  mpv \
  ocrmypdf \
  pandoc \
  poppler \
  tesseract-data-eng

# Networking & security
sudo pacman -S --noconfirm --needed \
  httpie \
  nmap \
  pgpdump

# AUR packages via paru (CachyOS ships paru by default)
if command -v paru &>/dev/null; then
  echo "  - Installing AUR packages via paru"
  paru -S --noconfirm --needed \
    websocat \
    kanata-bin
else
  echo "  - paru not found, installing AUR packages via cargo"
  if ! command -v websocat &>/dev/null; then
    echo "  - Installing websocat via cargo"
    cargo install websocat
  fi
  if ! command -v kanata &>/dev/null; then
    echo "  - Installing kanata via cargo"
    cargo install kanata
  fi
fi

# Virtualization (QEMU/KVM)
sudo pacman -S --noconfirm --needed \
  qemu-full \
  libvirt \
  virt-manager \
  virt-install \
  virt-viewer \
  bridge-utils \
  edk2-ovmf \
  swtpm \
  dnsmasq
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt "$USER" 2>/dev/null || true

# Quickemu (easy VM management + ISO downloads)
# Usage:
#   quickget windows 11          # downloads Windows 11 ISO + VirtIO drivers
#   quickemu --vm windows-11.conf  # boots the VM
#   quickget list                 # shows all available OSes
#   quickgui                      # GUI frontend
sudo pacman -S --noconfirm --needed quickemu
if command -v paru &>/dev/null; then
  paru -S --noconfirm --needed quickgui-bin 2>/dev/null || true
fi

# System info
sudo pacman -S --noconfirm --needed fastfetch

echo "  ✓ CLI tools installed"
