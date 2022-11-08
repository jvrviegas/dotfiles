#!/usr/bin/env bash

echo "• Cloning Kitty configs"
if [[ ! -r "$HOME/.config/kitty" ]]; then
    mkdir "$HOME/.config/kitty"
fi

if [[ ! -r "$HOME/.config/kitty/themes" ]]; then
    mkdir "$HOME/.config/kitty/themes"
fi

cp .config/kitty/kitty.conf ~/.config/kitty/
cp .config/kitty/onenord.conf ~/.config/kitty/themes/
