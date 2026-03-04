# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

macOS dotfiles repository managing development environment configurations: terminal emulators (Ghostty, Alacritty, Kitty, Wezterm), Neovim, tmux, zsh, window managers (yabai, skhd), and macOS system preferences.

## Setup Commands

```bash
source install.sh          # Full installation (copies dotfiles, installs Homebrew, formulae, casks, NVM, node, zsh plugins)
source osx.sh              # macOS system preferences (many options commented out — enable as needed)
source brew/formulae.sh    # Homebrew CLI tools only
source brew/cask.sh        # Homebrew GUI apps only
source brew/wm.sh          # Window manager tools (yabai, skhd)
```

There is also `install-script-company/install.sh` for company-specific installations.

## Architecture

### Deployment Model

**Critical distinction:** Most configs (`.gitconfig`, `.tmux.conf`, `.zshenv`, `.local/`, `.config/`) are **copied** to `$HOME` during installation. However, `.config/nvim/` is **symlinked** (`$HOME/.config/nvim` → `$(pwd)/.config/nvim`), so Neovim config changes are tracked directly in this repo. All other config changes must be made in this repo and re-copied.

### Configuration Structure

```
.config/
├── nvim/           # Neovim (symlinked, has its own CLAUDE.md — see there for nvim details)
├── zsh/            # Zsh config (ZDOTDIR via .zshenv)
│   ├── .zshrc      # Shell setup, plugins, PATH, NVM, Java
│   ├── .zsh_profile # Aliases, git helpers, FZF theme
│   └── zap_zsh.sh  # Zap plugin manager installer
├── ghostty/        # Ghostty terminal config
├── alacritty/      # Alacritty terminal config
├── kitty/          # Kitty terminal config
├── wezterm/        # Wezterm terminal config
├── tmux/           # Tmux colorscheme scripts
├── sketchybar/     # macOS menu bar (plugins/ and items/)
├── yabai/          # Tiling window manager
├── skhd/           # Hotkey daemon
├── starship/       # Starship prompt
.local/bin/         # Custom scripts (tmux-sessionizer, tmux-cht.sh, android-emulator.sh, etc.)
.zshenv             # Sets ZDOTDIR=$HOME/.config/zsh
.tmux.conf          # Tmux config (vi-mode, vim-like pane nav, monokai-pro theme)
.gitconfig          # Git config (default branch: main, merge tool: vimdiff, many aliases)
```

### Key Technologies

- **Shell**: zsh with [Zap](https://www.zapzsh.com/) plugin manager, Starship prompt
- **Editor**: Neovim (kickstart.nvim-based, see `.config/nvim/CLAUDE.md`)
- **Terminal multiplexer**: tmux with TPM
- **Navigation**: zoxide (`cd` aliased to `z`), fzf (Tokyonight theme)
- **Package managers**: Homebrew, NVM (not fnm), ASDF
- **Window management**: yabai + skhd (optional)

### Zsh Configuration

Zsh uses XDG-compliant `ZDOTDIR` set in `.zshenv` → `$HOME/.config/zsh`. Key aliases: `vim='nvim'`, `ls='eza --icons'`, `cd='z'`, `sozsh` (reload zsh config), `nvim-config` (edit nvim config), `nvim-dir` (cd to nvim config).

Git identity switching: `setupWorkGitlab()`, `setupPersonalGithub()`.

## Notes

- **Neovim has its own CLAUDE.md** at `.config/nvim/CLAUDE.md` with detailed plugin architecture, LSP servers, keymaps, and code style. Refer to that for all Neovim work.
- After config changes outside nvim, re-run `source install.sh` or manually copy changed files to `$HOME`.
- The README.md is outdated (references Vundle, OhMyZSH, bash files) — the repo has since migrated to zsh/Zap/kickstart.nvim.
