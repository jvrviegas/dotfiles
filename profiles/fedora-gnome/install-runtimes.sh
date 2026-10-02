#!/usr/bin/env bash

# Called by the Fedora package installer, or sourced for a targeted migration.
# Requires lib/deploy.sh and begin_deployment to have been loaded by the caller.
profile_install_runtimes() {
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v mise &>/dev/null; then
    echo "  - Installing mise"
    local installer
    installer=$(mktemp) || return
    if ! curl -fsSL https://mise.run -o "$installer"; then
      rm -f "$installer"
      return 1
    fi
    local status=0
    sh "$installer" || status=$?
    rm -f "$installer"
    [[ $status == 0 ]] || return "$status"
  fi

  deploy_file \
    "$DOTFILES_ROOT/profiles/fedora-gnome/home/.config/mise/config.toml" \
    "${XDG_CONFIG_HOME:-$HOME/.config}/mise/config.toml" || return

  echo "  - Installing Fedora runtimes with mise"
  # Use the global config explicitly: running install from a project must not
  # replace the Fedora defaults with that project's runtime requirements.
  mise install --cd "$HOME" || return
  mise exec --cd "$HOME" -- npm install -g markdownlint-cli tree-sitter-cli || return

  # Later package-install scripts also need the new Node/Bun on PATH.
  local runtime_env
  runtime_env=$(mise env --cd "$HOME" --shell bash) || return
  eval "$runtime_env"
}
