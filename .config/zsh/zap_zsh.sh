#!/usr/bin/env bash

echo "• Installing Zap"

if command -v zap &>/dev/null; then
  echo "  - Zap already installed"

else
  zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1 --keep
  echo "  - Done installing Zap"
fi;
