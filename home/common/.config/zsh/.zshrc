# Fedora and Omarchy use mise; macOS keeps its existing runtime managers.
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
_dotfiles_use_mise=0
if [[ -d /usr/share/omarchy || -f /etc/fedora-release ]] && command -v mise &>/dev/null; then
  _dotfiles_use_mise=1
else
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi
export PATH="${PATH}:${HOME}/.cargo/bin"

if [[ "$(uname)" == "Darwin" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"
  export PATH="$PNPM_HOME:$HOME/homebrew/bin:/opt/homebrew/opt/libpq/bin:$HOME/.opencode/bin:$HOME/.antigravity/antigravity/bin:$PATH"
  if command -v brew &> /dev/null && brew --prefix openjdk@17 &> /dev/null; then
    export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
  fi
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
  export ANDROID_HOME="$HOME/Android/Sdk"
  [ -d "/usr/lib64/dotnet" ] && export DOTNET_ROOT="/usr/lib64/dotnet"
  [[ $_dotfiles_use_mise == 0 ]] && export PATH="$PNPM_HOME:$PATH"
  for _jdk in /usr/lib/jvm/java-*-openjdk; do
    [ -d "$_jdk" ] && export JAVA_HOME="$_jdk"
  done
  unset _jdk
fi

# Omarchy keeps Starship at ~/.config/starship.toml. Other platforms retain
# this repository's XDG-style path.
if [[ -d /usr/share/omarchy ]]; then
  unset STARSHIP_CONFIG
else
  export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
fi
command -v starship &> /dev/null && eval "$(starship init zsh)"

# Interactive runtime switching on Fedora and Omarchy.
[[ $_dotfiles_use_mise == 1 ]] && eval "$(mise activate zsh)"

# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"
# Use ANSI palette slots so shell highlighting follows the active terminal theme.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=7'
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=1,bold'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=2'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=3'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=4'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=5'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=3'
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
plug "zsh-users/zsh-autosuggestions"
plug "zap-zsh/completions"
plug "zsh-users/zsh-syntax-highlighting"

# Load and initialise completion system
autoload -Uz compinit
compinit

# fzf
command -v fzf &> /dev/null && source <(fzf --zsh)

# FNM setup - is a fast node manager (replacement over nvm)
# eval "$(fnm env --use-on-cd --shell zsh)"
# source <(fnm completions --shell zsh)

# Keep nvm only where mise is not managing the runtimes.
if [[ ! -d /usr/share/omarchy && $_dotfiles_use_mise == 0 ]]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# source ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999

setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

command -v zoxide &> /dev/null && eval "$(zoxide init zsh)"

source $HOME/.config/zsh/.zsh_profile

# Legacy Bun completions belong only to the standalone installation.
[[ $_dotfiles_use_mise == 0 && -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# Go binaries (asdf)
command -v go &> /dev/null && export PATH="$PATH:$(go env GOBIN)"

export CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1

# Google Cloud CLI completion from its standard Linux installation location.
if [[ "$(uname)" == "Linux" && -f /opt/google-cloud-cli/completion.zsh.inc ]]; then
  source /opt/google-cloud-cli/completion.zsh.inc
fi
