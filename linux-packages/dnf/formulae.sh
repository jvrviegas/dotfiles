#!/usr/bin/env bash

# Install CLI tools via dnf (mirrors brew/formulae.sh)

echo "• Updating dnf and installing CLI tools"
sudo dnf upgrade -y --refresh

# Core utilities
sudo dnf install -y --skip-unavailable \
  coreutils \
  openssh \
  git \
  gh

# Editors
sudo dnf install -y --skip-unavailable \
  vim-enhanced \
  neovim

# Shell & prompt
sudo dnf install -y --skip-unavailable \
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
sudo dnf install -y --skip-unavailable \
  fd-find \
  ripgrep

# Lua
sudo dnf install -y --skip-unavailable \
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
sudo dnf install -y --skip-unavailable \
  dotnet-sdk-8.0 \
  java-25-openjdk-devel \
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
sudo dnf install -y --skip-unavailable \
  android-tools \
  yarnpkg

# scrcpy (not in default repos)
if ! command -v scrcpy &>/dev/null; then
  sudo dnf copr enable -y zeno/scrcpy 2>/dev/null && sudo dnf install -y --skip-unavailable scrcpy || \
    echo "  ⚠ scrcpy: install manually from https://github.com/Genymobile/scrcpy"
fi

# Containers
sudo dnf install -y --skip-unavailable docker-compose

# Data & databases
sudo dnf install -y --skip-unavailable \
  jq \
  sqlite

# Media & documents
sudo dnf install -y --skip-unavailable \
  ffmpeg-free \
  fmt \
  fontforge \
  libsixel-devel \
  mpv \
  ocrmypdf \
  pandoc-cli \
  poppler-utils \
  tesseract-langpack-eng

# Networking & security
sudo dnf install -y --skip-unavailable \
  httpie \
  nmap \
  pgpdump

# Build dependencies for cargo crates
sudo dnf install -y --skip-unavailable openssl-devel pkgconf-pkg-config

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

# Kanata setup: udev rule, input group, uinput module, systemd user service
if command -v kanata &>/dev/null; then
  echo "  - Configuring kanata (udev, input group, systemd)"
  KANATA_BIN="$(command -v kanata)"

  # Read /dev/input/event* and write /dev/uinput as a normal user
  sudo usermod -aG input "$USER" 2>/dev/null || true
  echo 'KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"' | \
    sudo tee /etc/udev/rules.d/99-kanata-uinput.rules > /dev/null
  sudo udevadm control --reload-rules
  sudo modprobe uinput
  # Re-apply the rule to the already-created node so no reboot is needed
  sudo udevadm trigger --action=add --subsystem-match=misc --sysname-match=uinput
  echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf > /dev/null

  mkdir -p "$HOME/.config/systemd/user"
  cat > "$HOME/.config/systemd/user/kanata.service" <<UNIT
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Type=simple
ExecStart=${KANATA_BIN} --cfg %h/.config/kanata/colemak_dhm.kbd
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
UNIT
  systemctl --user daemon-reload
  systemctl --user enable kanata.service 2>/dev/null || true
  echo "  - kanata service enabled (starts after you log out and back in)"
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
  # quickemu is in the Fedora repos; quickgui (GUI frontend) may not be
  sudo dnf install -y --skip-unavailable quickemu
  sudo dnf install -y --skip-unavailable quickgui 2>/dev/null || \
    echo "  - quickgui (GUI frontend) unavailable; quickemu CLI is enough"
fi

# AI
curl -fsSL https://claude.ai/install.sh | bash

# herdr (agent multiplexer / terminal workspace manager)
if ! command -v herdr &>/dev/null; then
  echo "  - Installing herdr"
  curl -fsSL https://herdr.dev/install.sh | sh
else
  echo "  - herdr already installed"
fi

# System info
sudo dnf install -y --skip-unavailable fastfetch

echo "  ✓ CLI tools installed"
