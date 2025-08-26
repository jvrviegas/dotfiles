#!/usr/bin/env bash

# Install cask apps
function installcask() {
	brew install --cask "${@}" 2> /dev/null
}

brew tap homebrew/cask-fonts

# Browsers
installcask google-chrome
installcask zen
installcask microsoft-edge

# Code
installcask ghostty
installcask docker
installcask orbstack
installcask postman
installcask visual-studio-code
installcask dbeaver-community
installcask mongodb-compass
installcask android-studio
installcask gcloud-cli

# Fonts
installcask font-jetbrains-mono-nerd-font
installcask font-hack-nerd-font

# Others
installcask raycast
installcask notion
installcask spotify
installcask karabiner-elements
installcask scroll-reverser
installcask android-file-transfer
installcask todoist-app
installcask akiflow
