#!/usr/bin/env bash

# Fedora Linux dotfiles installer
# Mirrors install.sh but uses dnf + Flatpak instead of Homebrew

set -e

# ─────────────────────────────────────────────
# 1. Copy dotfiles to $HOME
# ─────────────────────────────────────────────
echo "• Putting dotfiles in your home path: $HOME"

files=(
  "./.gitconfig"
  "./.tmux.conf"
  "./.tmux-cht-languages"
  "./.tmux-cht-command"
  "./.zshenv"
  "./.local"
  "./.config"
)

for file in ${files[@]}; do
    if [[ $(file $file | awk '{print $2}') == "directory" ]]; then
      [ -r "$file" ] && cp -r "$file" $HOME && echo "  - Copied folder $file"
    else
      [ -r "$file" ] && cp "$file" $HOME && echo "  - Copied file $file"
    fi;
done;
unset file files;
echo ""

# ─────────────────────────────────────────────
# 2. Install zsh & set as default shell
# ─────────────────────────────────────────────
echo "• Installing zsh"
if command -v zsh &>/dev/null; then
  echo "  - zsh already installed"
else
  sudo dnf install -y zsh
  echo "  - zsh installed"
fi

if [[ "$SHELL" != *"zsh"* ]]; then
  chsh -s "$(which zsh)"
  echo "  - Default shell changed to zsh (restart session to take effect)"
else
  echo "  - zsh is already the default shell"
fi
echo ""

# ─────────────────────────────────────────────
# 3. Install CLI tools via dnf
# ─────────────────────────────────────────────
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
  java-17-openjdk-devel \
  rustup

rustup-init -y --no-modify-path 2>/dev/null || true

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
  scrcpy \
  android-tools

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

# websocat (install via cargo)
if ! command -v websocat &>/dev/null; then
  echo "  - Installing websocat via cargo"
  cargo install websocat
else
  echo "  - websocat already installed"
fi

# Keyboard
# kanata (install via cargo or COPR)
if ! command -v kanata &>/dev/null; then
  echo "  - Installing kanata via cargo"
  cargo install kanata
else
  echo "  - kanata already installed"
fi

# System info
sudo dnf install -y fastfetch
echo ""

# ─────────────────────────────────────────────
# 4. Install GUI apps via Flatpak
# ─────────────────────────────────────────────
echo "• Installing GUI apps via Flatpak and dnf"

# Ensure Flatpak and Flathub are set up
sudo dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Browsers
flatpak install -y flathub com.google.Chrome
flatpak install -y flathub app.zen_browser.zen

# Terminals
sudo dnf install -y alacritty
# Ghostty — install from COPR if available
if ! command -v ghostty &>/dev/null; then
  echo "  - Ghostty: install manually from https://ghostty.org/download or COPR"
fi

# Development
flatpak install -y flathub com.google.AndroidStudio
flatpak install -y flathub io.dbeaver.DBeaverCommunity
flatpak install -y flathub com.getpostman.Postman

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
flatpak install -y flathub io.podman_desktop.PodmanDesktop

# Communication & productivity
flatpak install -y flathub com.slack.Slack
flatpak install -y flathub com.todoist.Todoist

# Media
flatpak install -y flathub com.spotify.Client

# Utilities
flatpak install -y flathub com.github.tchx84.Flatseal

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
echo ""

# ─────────────────────────────────────────────
# 5. NVM setup
# ─────────────────────────────────────────────
echo "• NVM Setup"
if [ ! -d "$HOME/.nvm" ]; then
  echo "  - Installing NVM"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
  echo "  - NVM already installed"
fi

# Add NVM setup to .zshrc (Linux paths)
if ! grep -q 'NVM_DIR' ~/.config/zsh/.zshrc 2>/dev/null; then
  echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.config/zsh/.zshrc
  echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.config/zsh/.zshrc
  echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.config/zsh/.zshrc
  echo "  - NVM setup added to .zshrc"
else
  echo "  - NVM setup already present in .zshrc"
fi
echo ""

# ─────────────────────────────────────────────
# 6. Neovim config symlink
# ─────────────────────────────────────────────
echo "• Setting up Neovim config symlink"
if [[ -d "$HOME/.config/nvim" ]] && [[ ! -L "$HOME/.config/nvim" ]]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim-old"
    echo "  - Backed up existing nvim config to $HOME/.config/nvim-old"
fi
if [[ ! -e "$HOME/.config/nvim" ]]; then
    ln -s "$(pwd)/.config/nvim" "$HOME/.config/nvim"
    echo "  - Created symlink from $HOME/.config/nvim to $(pwd)/.config/nvim"
else
    echo "  - Symlink already exists"
fi
echo ""

# ─────────────────────────────────────────────
# 7. TPM (Tmux Plugin Manager)
# ─────────────────────────────────────────────
echo "• Setting up TPM (Tmux Plugin Manager)"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  echo "  - TPM installed. Run 'prefix + I' inside tmux to install plugins"
else
  echo "  - TPM already installed"
fi
echo ""

# ─────────────────────────────────────────────
# 8. Node LTS & PNPM
# ─────────────────────────────────────────────
echo "• Installing Node LTS and PNPM"
# Source NVM for this session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
source node.sh

# Install Neovim tooling via npm
echo "  - Installing npm global tools (markdownlint-cli, tree-sitter-cli)"
npm i -g markdownlint-cli tree-sitter-cli

# Install bun
if ! command -v bun &>/dev/null; then
  echo "  - Installing Bun"
  curl -fsSL https://bun.sh/install | bash
else
  echo "  - Bun already installed"
fi
echo ""

# ─────────────────────────────────────────────
# 9. Zap (zsh plugin manager)
# ─────────────────────────────────────────────
echo "• Installing zsh plugins"
source .config/zsh/zap_zsh.sh

echo ""
echo "✓ Linux installation complete!"
echo "  - Restart your terminal or run 'exec zsh' to start using zsh"
echo "  - Run 'prefix + I' inside tmux to install tmux plugins"
