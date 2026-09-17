#!/usr/bin/env bash

# Window Management
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd
brew tap FelixKratz/formulae
brew install sketchybar

yabai --start-service
skhd --start-service
brew services start sketchybar
