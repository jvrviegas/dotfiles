#!/usr/bin/env bash

# Install command-line tools using Homebrew.
brew update
brew upgrade

# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install some other useful utilities like `sponge`.
#brew install moreutils

#brew install bash
brew install wget --with-iri
brew install bash-completion

# Install more recent versions of some OS X tools.
brew install vim --override-system-vi
brew install nvim
brew install openssh
brew install python

# Install everything else.
brew install git
brew install nmap
brew install ack
brew install imagemagick
brew install nvm
# Rip Grep
brew install rg
# Find replace
brew install fd

# Clean it up.
brew cleanup

