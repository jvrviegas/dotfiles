#!/usr/bin/env bash

# Install last node version
nvm install --lts

# Install PNPM
npm i -g pnpm

# Install Packages for development
pnpm add -g diagnostic-languageserver eslint eslint_d prettier_d_slim @fsouza/prettierd typescript typescript-language-server vscode-langservers-extracted cssmodules-language-server
