#!/usr/bin/env bash

# Arch/CachyOS dependencies needed by linux-desktop/gnome.sh.

echo "• Installing GNOME configuration dependencies"
sudo pacman -S --noconfirm --needed \
  bluez-libs \
  glib2 \
  gnome-shell-extensions \
  gtk-engine-murrine \
  meson \
  ninja \
  pkgconf \
  python-pipx \
  sassc
