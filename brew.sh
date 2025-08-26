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
brew install git
brew install nvm
# Rip Grep
brew install rg
# Find replace
brew install fzf

# Window Management
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd
brew tap FelixKratz/formulae
brew install sketchybar

# Clean it up.
brew cleanup

