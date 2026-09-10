#!/usr/bin/env bash

# Fedora dependencies needed by linux-desktop/gnome.sh.

echo "• Installing GNOME configuration dependencies"
sudo dnf install -y --skip-unavailable \
  bluez-libs-devel \
  glib2-devel \
  gnome-extensions-app \
  gnome-shell-extension-common \
  gtk-murrine-engine \
  meson \
  ninja-build \
  pipx \
  pkgconf-pkg-config \
  sassc
