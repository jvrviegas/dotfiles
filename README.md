# Dotfiles

Cross-platform dotfiles organized as shared home configuration plus explicit deployment profiles.

## Install

```bash
./install --profile macos
./install --profile fedora-gnome
./install --profile omarchy
```

Install only one phase when needed:

```bash
./install --profile omarchy --config-only
./install --profile omarchy --packages-only
```

Legacy entry points remain as thin wrappers:

```bash
./install.sh       # macos
./fedora.sh        # fedora-gnome
./omarchy.sh       # omarchy
```

## Layout

```text
home/common/                 Shared files, mirroring paths below $HOME
profiles/macos/              macOS home overlay, packages, and system settings
profiles/fedora-gnome/       Fedora GNOME overlay, packages, and desktop setup
profiles/omarchy/            Omarchy overlay, packages, and safe configuration
lib/deploy.sh                Shared backup and deployment module
install                      Unified installer interface
```

Profile `home/` directories mirror their destination. For example:

```text
profiles/omarchy/home/.config/hypr/input.lua
                           → ~/.config/hypr/input.lua
```

Replaced files are backed up under:

```text
~/.local/state/dotfiles-backups/<profile>-<timestamp>/
```

The retired generic Arch/Hyprland profile is intentionally unsupported. Use the `omarchy` profile for an Omarchy installation.
