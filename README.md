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

## Fedora runtimes

Fedora uses mise for Node LTS, Bun, Lua 5.4, and pnpm. Defaults live in
`profiles/fedora-gnome/home/.config/mise/config.toml`; project `mise.toml` files
can override them. LuaJIT and LuaRocks remain Fedora packages.

To migrate an existing Fedora setup, run:

```bash
./install --profile fedora-gnome
exec zsh
mise ls
```

The package phase installs mise and deploys its runtime configuration before
installing the runtimes and global npm helpers. The config phase enables mise
in zsh instead of nvm/asdf. Old `~/.nvm`, `~/.asdf`, and `~/.bun` directories
are left untouched for rollback. Reinstall any additional global npm packages
you need using the mise-managed Node. Fedora LuaRocks still targets its distro
Lua; it is not automatically configured for mise's Lua.

Run migration checks with `bash tests/fedora-runtimes.sh`.

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
