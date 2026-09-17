# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Cross-platform dotfiles repository with explicit deployment profiles for macOS, Fedora GNOME, and Omarchy.

## Setup Commands

```bash
./install --profile macos
./install --profile fedora-gnome
./install --profile omarchy
./install --profile omarchy --config-only
./install --profile omarchy --packages-only
```

`install.sh`, `fedora.sh`, and `omarchy.sh` are compatibility wrappers around the unified installer.

## Architecture

### Deployment Model

`install` is the only deployment interface. It loads `lib/deploy.sh`, then the selected adapter at `profiles/<profile>/profile.sh`. Shared and profile `home/` trees mirror paths under `$HOME`. Replaced files are backed up under `~/.local/state/dotfiles-backups/`.

Never recursively copy the repository into `$HOME`; use `deploy_file`, `deploy_overlay`, or `deploy_symlink` from the deployment module.

### Configuration Structure

```text
home/common/                    # Shared home overlay
├── .config/zsh/                # Zsh configuration
├── .config/{alacritty,ghostty,kitty,wezterm}/
├── .config/{git,kanata,starship,tmux}/
├── .local/bin/                 # Portable helper scripts
├── .gitconfig
├── .tmux.conf
└── .zshenv
profiles/
├── macos/                      # macOS overlay, Homebrew packages, system settings
├── fedora-gnome/               # Fedora overlay, dnf/Flatpak packages, GNOME settings
└── omarchy/                    # Omarchy-safe Hyprland, shell, XKB, and systemd files
lib/deploy.sh                   # Shared backup/deployment implementation
install                         # Unified installer interface
```

### Key Technologies

- **Shell**: zsh with [Zap](https://www.zapzsh.com/) plugin manager, Starship prompt
- **Editor**: Neovim
- **Terminal multiplexer**: tmux with TPM
- **Navigation**: zoxide (`cd` aliased to `z`), fzf
- **Package managers**: Homebrew (macOS), dnf/Flatpak (Fedora), Omarchy CLI (Omarchy)
- **Window management**: AeroSpace/Sketchybar (macOS), GNOME (Fedora), Hyprland/Omarchy Shell (Omarchy)

### Zsh Configuration

Zsh uses XDG-compliant `ZDOTDIR` set in `home/common/.zshenv` → `$HOME/.config/zsh`. Key aliases: `vim='nvim'`, `ls='eza --icons'`, `cd='z'`, `sozsh` (reload zsh config), `nvim-config` (edit nvim config), `nvim-dir` (cd to nvim config).

Git identity switching: `setupWorkGitlab()`, `setupPersonalGithub()`.

## GitHub Account Safety

For every GitHub CLI (`gh`) or authenticated GitHub operation in this repository:

1. Switch to the personal account first: `gh auth switch --hostname github.com --user jvrviegas`.
2. Perform the required GitHub/Git command(s).
3. Always switch back to the work account when finished, including after failures: `gh auth switch --hostname github.com --user joao-viegas-procimo`.

Use a shell `trap` or equivalent cleanup mechanism so the work account is restored even if a command exits with an error. Do not leave `jvrviegas` as the active account.

## Notes

- Keep shared files in `home/common/`; keep OS or desktop-specific files in the relevant profile.
- Apply changes with `./install --profile <profile> --config-only`.
- The generic Arch/Hyprland profile has been retired; use the Omarchy profile.
