#!/usr/bin/env bash

# Standalone Fedora GNOME setup. install_linux.sh runs the same dependency and
# desktop scripts in separate phases so Node.js is available to extensions.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/linux-packages/dnf/gnome.sh"
source "$SCRIPT_DIR/linux-desktop/gnome.sh"
