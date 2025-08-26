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

# Code
installcask android-studio
installcask dbeaver-community
installcask docker
installcask gcloud-cli
installcask ghostty
installcask mongodb-compass
installcask orbstack
installcask postman
installcask visual-studio-code

# Fonts
installcask font-jetbrains-mono-nerd-font
installcask font-hack-nerd-font

# Others
installcask akiflow
installcask android-file-transfer
installcask ankerwork
installcask karabiner-elements
installcask notion
installcask raycast
installcask scroll-reverser
installcask shottr
installcask spotify
installcask todoist-app
