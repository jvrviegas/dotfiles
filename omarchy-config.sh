#!/usr/bin/env bash

# Compatibility wrapper for configuration-only Omarchy deployment.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/install" --profile omarchy --config-only "$@"
