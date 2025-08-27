#!/usr/bin/env bash

# Install command-line tools using Homebrew.
brew update
brew upgrade

# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils

# Install more recent versions of some OS X tools.
brew install vim --override-system-vi
brew install nvim
brew install openssh

# Install everything else.
brew install asdf
brew install docker-compose
brew install eza
brew install fastlane
brew install fd
brew install ffmpeg
brew install fmt
brew install fzf
brew install git
brew install jq
brew install lua
brew install lua-language-server
brew install luajit
brew install luarocks
brew install nvm
brew install ripgrep
brew install rustup
brew install scrcpy
brew install sqlite
brew install starship
brew install tmux
brew install tree-sitter
brew install watchman
brew install yarn
brew install zoxide
brew install openjdk@17

# Clean it up.
brew cleanup

