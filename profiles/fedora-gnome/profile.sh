#!/usr/bin/env bash

profile_preflight() {
  [[ -r /etc/os-release ]] || {
    echo "✗ Cannot identify the operating system." >&2
    return 1
  }
  source /etc/os-release
  [[ ${ID:-} == fedora ]] || {
    echo "✗ The fedora-gnome profile requires Fedora." >&2
    return 1
  }
}

profile_install_packages() {
  echo "• Installing Fedora packages"
  source "$DOTFILES_ROOT/profiles/fedora-gnome/packages/formulae.sh"
  source "$DOTFILES_ROOT/profiles/fedora-gnome/packages/apps.sh"
  source "$DOTFILES_ROOT/profiles/fedora-gnome/packages/gnome.sh"

  if [[ ! -d $HOME/.nvm ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi
  export NVM_DIR="$HOME/.nvm"
  [[ -s $NVM_DIR/nvm.sh ]] && source "$NVM_DIR/nvm.sh"
  source "$DOTFILES_ROOT/lib/node.sh"
  npm i -g markdownlint-cli tree-sitter-cli
}

profile_install_config() {
  deploy_common_home

  echo "• Deploying Fedora GNOME configuration"
  deploy_overlay "$DOTFILES_ROOT/profiles/fedora-gnome/home"
  source "$DOTFILES_ROOT/profiles/fedora-gnome/configure-gnome.sh"

  if command -v zsh &>/dev/null; then
    local zsh_path current_shell
    zsh_path=$(command -v zsh)
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    [[ $current_shell == "$zsh_path" ]] || chsh -s "$zsh_path"
  fi

  echo "  - Fedora configuration validated"
}
