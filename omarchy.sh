#!/usr/bin/env bash

# Complete Omarchy setup: install the selected applications, then deploy the
# selected configuration without replacing Omarchy-managed desktop/theme files.

set -Eeuo pipefail
trap 'status=$?; echo "✗ Installation failed at line $LINENO: $BASH_COMMAND (exit $status)" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -eq 0 ]]; then
  echo "✗ Run this script as your regular user, not as root." >&2
  exit 1
fi

if ! command -v omarchy &>/dev/null; then
  echo "✗ Omarchy was not detected on this system." >&2
  exit 1
fi

if ! command -v mise &>/dev/null; then
  echo "✗ mise was not found. Omarchy normally installs it by default." >&2
  exit 1
fi

repo_packages=(
  # CLI and development tools
  lua-language-server
  jdk17-openjdk
  rustup
  scrcpy
  httpie
  pgpdump

  # Terminal and Android tools
  alacritty
  android-tools

  # Desktop applications available from Arch/Omarchy repositories
  dbeaver
  visual-studio-code-bin
  spotify
)

aur_packages=(
  google-cloud-cli
  mongodb-compass-bin
  postman-bin
  slack-desktop
)

echo "• Installing repository packages"
omarchy pkg add "${repo_packages[@]}"
echo ""

echo "• Installing AUR packages"
omarchy pkg aur add "${aur_packages[@]}"
echo ""

echo "• Installing development tools with mise"
mise use --global node@lts
mise use --global pnpm@latest
mise use --global yarn@latest
mise use --global bun@latest
mise use --global pi@latest
echo ""

echo "• Installing Claude Code"
if command -v claude &>/dev/null; then
  echo "  - Claude Code is already installed"
else
  curl -fsSL https://claude.ai/install.sh | bash
fi
echo ""

if ! rustup default &>/dev/null; then
  echo "• Installing the stable Rust toolchain"
  rustup default stable
  echo ""
fi

echo "✓ Selected Omarchy applications are installed."
echo ""

echo "════════════════════════════════════════════════════════════"
echo "  Configuring dotfiles and services"
echo "════════════════════════════════════════════════════════════"
echo ""

"$SCRIPT_DIR/omarchy-config.sh"

echo ""
echo "✓ Omarchy installation complete!"
echo "  Log out and back in to activate Zsh and any new group membership."
