export PNPM_HOME="$HOME/Library/pnpm"

export PATH="$PNPM_HOME:$HOME/.local/bin:$PATH"
eval "$(starship init zsh)"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:~/.local/bin:$PATH
export PATH=$HOME/homebrew/bin:$PATH
export PATH="${PATH}:${HOME}/.cargo/env"

export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"

# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"
plug "zsh-users/zsh-autosuggestions"
plug "zap-zsh/completions"
plug "zsh-users/zsh-syntax-highlighting"

# Load and initialise completion system
autoload -Uz compinit
compinit

# zsh
source <(fzf --zsh)

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

eval "$(zoxide init zsh)"

source $HOME/.zsh_profile

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Change Starship config file path
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# bun completions
[ -s "/Users/joaoviegas/.bun/_bun" ] && source "/Users/joaoviegas/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
