#!/usr/bin/env bash

profile_preflight() {
  [[ $(uname -s) == Darwin ]] || {
    echo "✗ The macos profile requires macOS." >&2
    return 1
  }
}

profile_install_packages() {
  echo "• Installing macOS packages"
  if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  source "$DOTFILES_ROOT/profiles/macos/packages/formulae.sh"
  source "$DOTFILES_ROOT/profiles/macos/packages/apps.sh"
  brew install --cask nikitabobko/tap/aerospace
  brew tap FelixKratz/formulae
  brew install sketchybar

  export NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"
  source "$(brew --prefix nvm)/nvm.sh"
  source "$DOTFILES_ROOT/lib/node.sh"
}

profile_install_config() {
  deploy_common_home

  echo "• Deploying macOS configuration"
  deploy_overlay "$DOTFILES_ROOT/profiles/macos/home"
  echo "  - macOS configuration validated"
}
