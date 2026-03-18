# sudo askpass helper (enables sudo in non-interactive contexts like IDE terminals)
if [ -f /usr/bin/lxqt-openssh-askpass ]; then
  export SUDO_ASKPASS=/usr/bin/lxqt-openssh-askpass
fi

# PATH setup
export PNPM_HOME="$HOME/Library/pnpm"
export BUN_INSTALL="$HOME/.bun"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export DOTNET_ROOT="/opt/homebrew/Cellar/dotnet/10.0.102/libexec"
export PATH="$PNPM_HOME:$BUN_INSTALL/bin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:$HOME/homebrew/bin:/opt/homebrew/opt/libpq/bin:$HOME/.opencode/bin:$HOME/.antigravity/antigravity/bin:$PATH"
export PATH="${PATH}:${HOME}/.cargo/env"

if command -v brew &> /dev/null && brew --prefix openjdk@17 &> /dev/null; then
  export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
fi

export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
command -v starship &> /dev/null && eval "$(starship init zsh)"

# Created by Zap installer
if [ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ]; then
  source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"
  plug "zsh-users/zsh-autosuggestions"
  plug "zap-zsh/completions"
  plug "zsh-users/zsh-syntax-highlighting"
fi

# Load and initialise completion system
autoload -Uz compinit
compinit

# fzf
command -v fzf &> /dev/null && source <(fzf --zsh)

# FNM setup - is a fast node manager (replacement over nvm)
# eval "$(fnm env --use-on-cd --shell zsh)"
# source <(fnm completions --shell zsh)

# NVM setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Go binaries (asdf)
command -v go &> /dev/null && export PATH="$PATH:$(go env GOBIN)"
