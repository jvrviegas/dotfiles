#!/usr/bin/env bash

# Install command-line tools using Homebrew.
brew update
brew upgrade

# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils

# Install everything else.
brew install docker-compose
brew install fastlane
brew install git
brew install nvm
brew install watchman
brew install openjdk@17

# Clean it up.
brew cleanup

