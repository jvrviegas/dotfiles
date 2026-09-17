#!/usr/bin/env bash

# Dependencies needed by the Fedora GNOME profile configuration.

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
