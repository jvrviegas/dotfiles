#!/usr/bin/env bash

# Install command-line tools using Homebrew.
brew update
brew upgrade

# Core utilities
# Don't forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
brew install openssh
brew install git
brew install gh

# Editors
brew install vim --override-system-vi
brew install nvim

# Shell & prompt
brew install fzf
brew install eza
brew install starship
brew install tmux
brew install zoxide

# Search & navigation
brew install fd
brew install ripgrep

# Lua
brew install lua
brew install lua-language-server
brew install luajit
brew install luarocks

# Node.js & JavaScript
brew install nvm
brew install oven-sh/bun/bun
brew install yarn

# Languages & runtimes
brew install asdf
brew install dotnet
brew install openjdk@17
brew install rustup

# Mobile development
brew install cocoapods
brew install fastlane
brew install scrcpy
brew install watchman
brew install xcodegen

# Containers
brew install docker-compose

# Data & databases
brew install jq
brew install sqlite

# Media & documents
brew install ffmpeg
brew install fmt
brew install fontforge
brew install libsixel
brew install mpv
brew install ocrmypdf
brew install pandoc
brew install poppler
brew install tesseract-lang
brew install banh-canh/ytui/ytui

# Neovim tooling
brew install markdownlint-cli
brew install tree-sitter

# Networking & security
brew install httpie
brew install nmap
brew install pgpdump
brew install websocat

# Keyboard & audio
brew install kanata
brew install kanata-tray
brew install switchaudio-osx

# AI
curl -fsSL https://claude.ai/install.sh | bash

# System info
brew install neofetch

# Clean it up.
brew cleanup
