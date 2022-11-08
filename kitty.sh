#!/usr/bin/env bash

echo "• Cloning Kitty configs"
if [[ -r "$HOME/.config/kitty" ]]; then
    mkdir "$HOME/.config/kitty"
    mkdir "$HOME/.config/kitty/themes"
fi

cp -R .config/kitty ~/.config
