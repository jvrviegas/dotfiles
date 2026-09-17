#!/usr/bin/env bash

# Shared deployment module. Profile adapters call this interface instead of
# implementing their own copying, backup, and validation behavior.

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DEPLOY_BACKUP_ROOT=""
DEPLOY_BACKUP_CREATED=false

begin_deployment() {
  local profile=$1
  DEPLOY_BACKUP_ROOT="$HOME/.local/state/dotfiles-backups/${profile}-$(date +%Y%m%d-%H%M%S)"
  DEPLOY_BACKUP_CREATED=false
}

backup_path() {
  local destination=$1 relative
  [[ -e $destination || -L $destination ]] || return 0

  relative=${destination#"$HOME"/}
  [[ -e $DEPLOY_BACKUP_ROOT/$relative || -L $DEPLOY_BACKUP_ROOT/$relative ]] && return 0
  mkdir -p "$DEPLOY_BACKUP_ROOT/$(dirname "$relative")"
  if [[ -L $destination && -e $destination ]]; then
    cp -pRL "$destination" "$DEPLOY_BACKUP_ROOT/$relative"
  else
    cp -pR "$destination" "$DEPLOY_BACKUP_ROOT/$relative"
  fi
  DEPLOY_BACKUP_CREATED=true
}

deploy_file() {
  local source=$1 destination=$2 mode=${3:-}
  [[ -f $source ]] || {
    echo "✗ Missing deployment source: $source" >&2
    return 1
  }

  if [[ -f $destination ]] && cmp -s "$source" "$destination"; then
    echo "  - Unchanged: ${destination/#$HOME/~}"
    return 0
  fi

  [[ -n $mode ]] || { [[ -x $source ]] && mode=755 || mode=644; }
  backup_path "$destination"
  mkdir -p "$(dirname "$destination")"
  install -m "$mode" "$source" "$destination"
  echo "  - Installed: ${destination/#$HOME/~}"
}

deploy_symlink() {
  local source=$1 destination=$2

  if [[ -L $destination && $(readlink "$destination") == "$source" ]]; then
    echo "  - Unchanged: ${destination/#$HOME/~}"
    return 0
  fi

  backup_path "$destination"
  rm -rf "$destination"
  mkdir -p "$(dirname "$destination")"
  ln -s "$source" "$destination"
  echo "  - Linked: ${destination/#$HOME/~} -> $source"
}

deploy_overlay() {
  local source_root=$1 destination_root=${2:-$HOME}
  [[ -d $source_root ]] || {
    echo "✗ Missing deployment overlay: $source_root" >&2
    return 1
  }

  # Convert legacy directory symlinks into managed directories before writing
  # files through them. This prevents deployment from mutating repository data.
  while IFS= read -r -d '' source_directory; do
    local directory_relative=${source_directory#"$source_root"/}
    local destination_directory="$destination_root/$directory_relative"

    if [[ -L $destination_directory || ( -e $destination_directory && ! -d $destination_directory ) ]]; then
      backup_path "$destination_directory"
      rm -rf "$destination_directory"
    fi
    mkdir -p "$destination_directory"
  done < <(find "$source_root" -mindepth 1 -type d -print0)

  while IFS= read -r -d '' source; do
    local relative=${source#"$source_root"/}
    local destination="$destination_root/$relative"

    if [[ -L $source ]]; then
      deploy_symlink "$(readlink "$source")" "$destination"
    elif [[ -f $source ]]; then
      deploy_file "$source" "$destination"
    fi
  done < <(find "$source_root" \( -type f -o -type l \) -print0)
}

deploy_common_home() {
  echo "• Deploying shared configuration"
  deploy_overlay "$DOTFILES_ROOT/home/common"
  deploy_overlay "$DOTFILES_ROOT/agent-skills" "$HOME/.agents/skills"

  mkdir -p "$HOME/.config/theme" "$HOME/.config/tmux/themes"
  if [[ ! -f $HOME/.config/theme/current ]]; then
    printf '%s\n' 'the-mandalorian' >"$HOME/.config/theme/current"
  fi

  local current_theme
  current_theme=$(<"$HOME/.config/theme/current")
  if [[ -f $DOTFILES_ROOT/home/common/.config/tmux/themes/$current_theme.sh ]]; then
    deploy_file \
      "$DOTFILES_ROOT/home/common/.config/tmux/themes/$current_theme.sh" \
      "$HOME/.config/tmux/themes/current.sh" 755
  fi

  if command -v zsh &>/dev/null; then
    if [[ ! -f ${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh ]]; then
      zsh <(curl -fsSL https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) \
        --branch release-v1 --keep
    fi
    zsh -n "$HOME/.config/zsh/.zshrc"
    zsh -n "$HOME/.config/zsh/.zsh_profile"
  else
    echo "  ! zsh is not installed; skipped Zap installation and syntax checks"
  fi
}

finish_deployment() {
  if [[ $DEPLOY_BACKUP_CREATED == true ]]; then
    echo "• Replaced files were backed up to: $DEPLOY_BACKUP_ROOT"
  fi
}
