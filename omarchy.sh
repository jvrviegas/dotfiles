#!/usr/bin/env bash

# Compatibility wrapper. Prefer: ./install --profile omarchy
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/install" --profile omarchy "$@"
