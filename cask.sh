#!/usr/bin/env bash

# Install cask apps
function installcask() {
	brew install --cask "${@}" 2> /dev/null
}

brew tap homebrew/cask-fonts

# Browsers
# installcask google-chrome
# installcask brave-browser

# Code
installcask gpgtools
installcask docker
installcask orbstack
installcask postman
# installcask visual-studio-code
installcask insomnia
installcask dbeaver-community
installcask mongodb-compass
installcask kitty

# Fonts
installcask font-caskaydia-cove-nerd-font
installcask font-jetbrains-mono-nerd-font
installcask font-hack-nerd-font

# Others
installcask raycast
installcask notion
# installcask slack
installcask spotify
installcask discord
installcask gimp
installcask inkdrop
installcask iterm2
installcask karabiner-elements
installcask menumeters
installcask scroll-reverser
# installcask telegram
# installcask textmate
# installcask zoom
