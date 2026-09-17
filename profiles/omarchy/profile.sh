#!/usr/bin/env bash

profile_preflight() {
  [[ $EUID -ne 0 ]] || {
    echo "✗ Run the Omarchy profile as your regular user, not root." >&2
    return 1
  }
  command -v omarchy &>/dev/null || {
    echo "✗ Omarchy was not detected on this system." >&2
    return 1
  }
}

profile_install_packages() {
  command -v mise &>/dev/null || {
    echo "✗ mise was not found. Omarchy normally installs it by default." >&2
    return 1
  }

  local repo_packages=(
    lua-language-server jdk17-openjdk rustup scrcpy httpie pgpdump
    alacritty android-tools dbeaver visual-studio-code-bin spotify zsh
  )
  local aur_packages=(
    google-cloud-cli mongodb-compass-bin postman-bin slack-desktop kanata-bin
  )

  echo "• Installing Omarchy repository packages"
  omarchy pkg add "${repo_packages[@]}"
  echo "• Installing Omarchy AUR packages"
  omarchy pkg aur add "${aur_packages[@]}"

  echo "• Installing development tools with mise"
  mise use --global node@lts
  mise use --global pnpm@latest
  mise use --global yarn@latest
  mise use --global bun@latest
  mise use --global pi@latest

  if ! command -v claude &>/dev/null; then
    curl -fsSL https://claude.ai/install.sh | bash
  fi
  rustup default &>/dev/null || rustup default stable
}

profile_install_config() {
  source "$DOTFILES_ROOT/profiles/omarchy/configure.sh"
}
