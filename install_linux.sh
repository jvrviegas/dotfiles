#!/usr/bin/env bash

# Linux dotfiles installer
# Mirrors install.sh but uses native package managers instead of Homebrew

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────────
# 1. Select distro / package manager
# ─────────────────────────────────────────────

# Map folder names to display labels
declare -A PKG_LABELS=(
  [dnf]="Fedora / RHEL / dnf-based"
  [pacman]="CachyOS / Arch / pacman-based"
)

# Discover available package folders inside linux-packages/
available=()
for dir in "$SCRIPT_DIR"/linux-packages/*/; do
  folder="$(basename "$dir")"
  [[ -f "$dir/formulae.sh" ]] && available+=("$folder")
done

if [[ ${#available[@]} -eq 0 ]]; then
  echo "✗ No package folders found (expected e.g. dnf/, pacman/, apt/ with formulae.sh)"
  exit 1
fi

if [[ ${#available[@]} -eq 1 ]]; then
  PKG_DIR="${available[0]}"
  label="${PKG_LABELS[$PKG_DIR]:-$PKG_DIR}"
  echo "• Detected package manager: $label ($PKG_DIR/)"
else
  echo "• Select your distro / package manager:"
  for i in "${!available[@]}"; do
    folder="${available[$i]}"
    label="${PKG_LABELS[$folder]:-$folder}"
    echo "    $((i + 1))) $label"
  done

  read -rp "  Enter choice [1-${#available[@]}]: " pkg_choice
  idx=$((pkg_choice - 1))

  if [[ $idx -lt 0 || $idx -ge ${#available[@]} ]]; then
    echo "  ✗ Invalid choice, aborting."
    exit 1
  fi

  PKG_DIR="${available[$idx]}"
fi

echo ""

# ─────────────────────────────────────────────
# 2. Copy dotfiles to $HOME
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
# 3. Install zsh & set as default shell
# ─────────────────────────────────────────────
echo "• Installing zsh"
if command -v zsh &>/dev/null; then
  echo "  - zsh already installed"
else
  case "$PKG_DIR" in
    dnf)    sudo dnf install -y zsh ;;
    pacman) sudo pacman -S --noconfirm zsh ;;
    apt)    sudo apt install -y zsh ;;
    *)      echo "  ✗ Unknown package manager, install zsh manually"; exit 1 ;;
  esac
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
# 4. Packages (CLI tools, GUI apps, WM)
# ─────────────────────────────────────────────
source "linux-packages/$PKG_DIR/formulae.sh"
echo ""
source "linux-packages/$PKG_DIR/apps.sh"
echo ""

# Window manager (optional)
if [[ -f "linux-packages/$PKG_DIR/wm.sh" ]]; then
  read -p "• Install Hyprland + Quickshell + Vicinae window management stack? [y/N] " wm_choice
  if [[ "$wm_choice" =~ ^[Yy]$ ]]; then
    source "linux-packages/$PKG_DIR/wm.sh"
  fi
  echo ""
fi

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
# 7. Theme system
# ─────────────────────────────────────────────
echo "• Setting up theme system"
mkdir -p "$HOME/.config/theme"
mkdir -p "$HOME/.config/tmux/themes"
mkdir -p "$HOME/.config/wallpapers"
cp "$(pwd)/.config/tmux/themes/"*.sh "$HOME/.config/tmux/themes/" 2>/dev/null || true
chmod +x "$HOME/.config/tmux/themes/"*.sh 2>/dev/null || true
if [ ! -f "$HOME/.config/theme/current" ]; then
  echo "the-mandalorian" > "$HOME/.config/theme/current"
fi
CURRENT_THEME=$(cat "$HOME/.config/theme/current")
if [ -f "$HOME/.config/tmux/themes/${CURRENT_THEME}.sh" ]; then
  cp "$HOME/.config/tmux/themes/${CURRENT_THEME}.sh" "$HOME/.config/tmux/themes/current.sh"
fi
echo "  - Theme set to: $CURRENT_THEME"
echo ""

# ─────────────────────────────────────────────
# 8. TPM (Tmux Plugin Manager)
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
# 9. Node LTS & PNPM
# ─────────────────────────────────────────────
echo "• Installing Node LTS and PNPM"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
source node.sh

echo "  - Installing npm global tools (markdownlint-cli, tree-sitter-cli)"
npm i -g markdownlint-cli tree-sitter-cli

if ! command -v bun &>/dev/null; then
  echo "  - Installing Bun"
  curl -fsSL https://bun.sh/install | bash
else
  echo "  - Bun already installed"
fi
echo ""

# ─────────────────────────────────────────────
# 10. Zap (zsh plugin manager)
# ─────────────────────────────────────────────
echo "• Installing zsh plugins"
source .config/zsh/zap_zsh.sh

echo ""
echo "✓ Linux installation complete!"
echo "  - Restart your terminal or run 'exec zsh' to start using zsh"
echo "  - Run 'prefix + I' inside tmux to install tmux plugins"

# ─────────────────────────────────────────────
# Post-install: optional setup tasks
# ─────────────────────────────────────────────
echo ""
echo "• Optional post-install tasks:"
echo ""

read -rp "  Download Windows 11 VM via quickemu? [y/N] " dl_win
if [[ "$dl_win" =~ ^[Yy]$ ]]; then
  mkdir -p "$HOME/VMs" && cd "$HOME/VMs"
  quickget windows 11
  echo "  - Windows 11 VM ready at ~/VMs/"
  echo "  - Run: cd ~/VMs && quickemu --vm windows-11.conf"
  cd "$SCRIPT_DIR"
fi
