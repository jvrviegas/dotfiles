#!/usr/bin/env bash

# Dependencies needed by the Fedora GNOME profile configuration.

# xprop is required by Pop Shell.
echo "• Installing GNOME configuration dependencies"
sudo dnf install -y --skip-unavailable \
  bluez-libs-devel \
  glib2-devel \
  gnome-extensions-app \
  gnome-shell-extension-common \
  gnome-shell-extension-pop-shell \
  pop-launcher \
  xprop \
  gtk-murrine-engine \
  meson \
  ninja-build \
  pipx \
  pkgconf-pkg-config \
  sassc
