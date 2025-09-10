#!/usr/bin/env bash

# Install cask apps
function installcask() {
	brew install --cask "${@}" 2> /dev/null
}

# Browsers
installcask google-chrome

# Code
installcask android-studio
installcask dbeaver-community
installcask docker
installcask gcloud-cli
installcask orbstack
installcask postman
installcask visual-studio-code

# Others
installcask spotify
installcask clickup
installcask iterm2
