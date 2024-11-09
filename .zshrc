export PNPM_HOME="$HOME/Library/pnpm"

export PATH="$PNPM_HOME:$HOME/.local/bin:$PATH"
eval "$(starship init zsh)"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:~/.local/bin:$PATH
export PATH=$HOME/homebrew/bin:$PATH
export PATH="${PATH}:${HOME}/.cargo/env"

export JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk.jdk/Contents/Home
export ANDROID_HOME=~/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"
plug "zsh-users/zsh-autosuggestions"
# plug "zap-zsh/supercharge"
plug "zap-zsh/completions"
# plug "wintermi/zsh-starship"
# plug "zap-zsh/zap-prompt"
plug "zsh-users/zsh-syntax-highlighting"

# Load and initialise completion system
autoload -Uz compinit
compinit

# zsh
source <(fzf --zsh)
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias luamake=/Users/joaovitor-work/.config/nvim/ls/lua-language-server/3rd/luamake/luamake

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
