#!/usr/bin/env bash

# Install cask apps
function installcask() {
	brew install --cask "${@}" 2> /dev/null
}

brew tap homebrew/cask-fonts

# Browsers
installcask google-chrome
installcask microsoft-edge
installcask zen

# Terminals
installcask alacritty
installcask ghostty
installcask kitty

# Development
installcask android-platform-tools
installcask android-studio
installcask dbeaver-community
installcask gcloud-cli
installcask mongodb-compass
installcask postman
installcask visual-studio-code

# Containers
installcask docker-desktop
installcask orbstack

# Communication & productivity
installcask akiflow
installcask slack
installcask todoist-app

# Fonts & typography
installcask font-fantasque-sans-mono-nerd-font
installcask font-hack-nerd-font
installcask font-jetbrains-mono-nerd-font
installcask font-maple-mono
installcask font-maple-mono-nf
installcask font-sf-mono
installcask font-sf-pro
installcask fontforge-app
installcask sf-symbols

# Documents & writing
installcask basictex

# Media
installcask spotify

# Utilities
installcask android-file-transfer
installcask ankerwork
installcask karabiner-elements
installcask raycast
installcask scroll-reverser
installcask shottr
installcask spaceman
