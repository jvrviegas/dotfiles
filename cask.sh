#!/usr/bin/env bash

# Install cask apps
function installcask() {
	brew cask install "${@}" 2> /dev/null
}

# Browsers
installcask google-chrome

# Code
installcask gpgtools
installcask docker
installcask postman
installcask insomnia

# Others
installcask notion
installcask slack
