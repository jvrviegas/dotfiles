# Fedora GNOME Install Checklist

Use this checklist to decide what to keep in the Fedora GNOME installer. Uncheck tools you no longer use, then remove them from:

- `profiles/fedora-gnome/packages/formulae.sh`
- `profiles/fedora-gnome/packages/apps.sh`
- `profiles/fedora-gnome/packages/gnome.sh`

Legend:

- `[dep]` = dependency/support package used by another tool, script, build, theme, or config step.
- `[repo]` = installed after adding an external RPM/COPR repo.
- `[script]` = installed via upstream install script.
- `[flatpak]` = installed from Flathub.
- `[cargo]` = installed via Cargo.
- `[manual download]` = downloaded directly into user directories.

## System/core utilities

- [x] `coreutils` [dep] — base GNU utilities.
- [x] `curl` [dep] — required by install scripts/downloads.
- [x] `less` [dep] — used by cheat helpers.
- [x] `lsof` [dep] — used by `checkPort.sh`.
- [x] `openssh` [dep] — SSH/client support, `work-sync`.
- [x] `procps-ng` [dep] — provides `pgrep`, used by tmux/work-sync scripts.
- [x] `python3` [dep] — used by `theme-switch`, `work-sync`, GNOME config helpers.
- [x] `rsync` [dep] — used by `work-sync`.
- [x] `ruby` [dep] — used by `diff-highlight` wrapper.
- [x] `unzip` [dep] — needed for Maple Mono font extraction.
- [x] `git` [dep] — required by theme/extension/asdf installs and general dev.
- [x] `gh` — GitHub CLI.
- [x] `flatpak` [dep] — required for Flatpak app installs.

## Editors

- [x] `vim-enhanced`
- [x] `neovim`
- [x] `code` [repo] — Visual Studio Code from Microsoft RPM repo.

## Shell, terminal, prompt

- [x] `zsh` — default shell and dotfiles shell config.
- [x] `fzf` — fuzzy finder used by shell/tmux/herdr helpers.
- [x] `eza` — `ls` replacement in shell aliases.
- [x] `tmux` — terminal multiplexer.
- [x] `zoxide` — smart `cd` replacement.
- [x] `starship` [script] — shell prompt.
- [] `alacritty`
- [x] `kitty`
- [] `wezterm` [repo] — installed via COPR.
- [x] `ghostty` [repo] — tried via DNF/COPR; used by GNOME terminal shortcut.

## Search/navigation

- [x] `fd-find` — used by sessionizer scripts.
- [x] `ripgrep`

## Languages/runtimes/toolchains

- [ ] `lua`
- [x] `luajit`
- [x] `luarocks`
- [x] `lua-language-server` [manual download]
- [ ] `dotnet-sdk-8.0`
- [x] `java-25-openjdk-devel`
- [x] `rustup` [dep] — enables Rust/Cargo setup.
- [x] `cargo` [dep] — installed/activated via Rust; required for Cargo-installed tools.
- [ ] `asdf` [manual git clone]
- [ ] `nvm` [script]
- [ ] `node LTS` [script]
- [x] `pnpm` [npm global]
- [x] `yarnpkg`
- [ ] `bun` [script]
- [x] `markdownlint-cli` [npm global]
- [x] `tree-sitter-cli` [npm global]

## Mobile development

- [x] `android-tools`
- [x] `scrcpy` [repo] — via COPR if available.
- [x] `com.google.AndroidStudio` [flatpak]

## Containers/virtualization

- [x] `docker-compose`
- [x] `virtualization` DNF group
- [x] `libvirtd` service enablement [dep] — required by virtualization.
- [x] `libvirt` group membership [dep] — required for user VM access.
- [x] `quickemu`
- [x] `quickgui`
- [ ] `io.podman_desktop.PodmanDesktop` [flatpak]

## Cloud/devops

- [x] `google-cloud-cli` [repo]
- [x] `libxcrypt-compat` [dep] — installed with Google Cloud CLI.

## Data/databases

- [x] `jq` — used by `herdr-sessionizer` and general scripting.
- [x] `sqlite`
- [x] `io.dbeaver.DBeaverCommunity` [flatpak]
- [x] `com.mongodb.Compass` [flatpak]

## Media/documents

- [x] `ffmpeg-free`
- [x] `fmt`
- [x] `fontforge`
- [x] `libsixel-devel`
- [x] `mpv`
- [x] `ocrmypdf`
- [x] `pandoc-cli`
- [x] `poppler-utils`
- [x] `tesseract-langpack-eng`
- [x] `texlive-scheme-basic`

## Networking/security

- [ ] `httpie`
- [ ] `nmap`
- [x] `pgpdump`
- [x] `openssl-devel` [dep] — build dependency for Cargo crates.
- [x] `pkgconf-pkg-config` [dep] — build dependency for Cargo crates and GNOME config dependencies.
- [x] `websocat` [cargo]

## Keyboard/input

- [x] `kanata` [cargo]
- [x] `input` group membership [dep] — required by Kanata.
- [x] `uinput` udev rule/module setup [dep] — required by Kanata.
- [x] `kanata.service` systemd user service [dep] — runs Kanata.

## GUI apps

- [x] `com.google.Chrome` [flatpak]
- [x] `app.zen_browser.zen` [flatpak]
- [x] `com.getpostman.Postman` [flatpak]
- [x] `com.slack.Slack` [flatpak]
- [ ] `com.todoist.Todoist` [flatpak]
- [x] `com.spotify.Client` [flatpak]
- [x] `com.github.tchx84.Flatseal` [flatpak]
- [x] `com.mattjakeman.ExtensionManager` [flatpak]
- [x] `flameshot` — GNOME screenshot shortcut uses this.

## Fonts

- [x] `JetBrainsMono Nerd Font` [manual download]
- [ ] `Hack Nerd Font` [manual download]
- [ ] `FantasqueSansMono Nerd Font` [manual download]
- [ ] `Maple Mono NF` [manual download]

## AI / agent tools

- [x] `claude` [script]
- [x] `opencode` [script]
- [x] `pi` [script]
- [x] `codex` []
- [x] `herdr` [script]

## GNOME configuration dependencies

- [x] `bluez-libs-devel` [dep] — GNOME extension/theme build support.
- [x] `glib2-devel` [dep] — GNOME extension/theme build support.
- [x] `gnome-extensions-app`
- [x] `gnome-shell-extension-common` [dep] — shared GNOME extension support, including Pop Shell.
- [x] `pop-launcher` [dep] — application launcher used by Pop Shell (`Super+Space`).
- [x] `xprop` [dep] — required by Pop Shell.
- [x] `gtk-murrine-engine` [dep] — GTK theme rendering support.
- [x] `meson` [dep] — theme/extension build tool.
- [x] `ninja-build` [dep] — theme/extension build tool.
- [x] `pipx` [dep] — installs `gnome-extensions-cli`.
- [x] `sassc` [dep] — GTK/GNOME theme compilation.
- [x] `gnome-extensions-cli` / `gext` [pipx] — installed during config if missing.

## GNOME themes

- [ ] `WhiteSur GTK theme` [manual git clone]
- [ ] `WhiteSur icon theme` [manual git clone]

## GNOME extensions

- [x] `Pop Shell` (`gnome-shell-extension-pop-shell`) — tiling window management; uses `pop-launcher`, `gnome-shell-extension-common`, and `xprop`.
- [ ] `Forge`
- [x] `Vitals`
- [x] `Dash to Dock`
- [x] `Blur My Shell`
- [ ] `Just Perfection`
- [ ] `Vertical Workspaces`
- [ ] `Open Bar`
- [x] `User Themes`
- [x] `GSConnect`
- [x] `Junk Notification Cleaner`
- [x] `Move Clock`
- [x] `Space Bar`
- [x] `Compiz alike Magic Lamp`
- [x] `Tailscale Status` [manual git clone]
- [x] `Earport` [manual git clone]
- [x] `Coding Agent Rate Limit Indicator` [manual git clone]
- [ ] `Vicinae GNOME extension` [manual download] — installed only if `vicinae` command exists.

## Installer side effects / system configuration

- [x] DNF system upgrade with `sudo dnf upgrade -y --refresh`.
- [x] Flathub remote setup.
- [x] Google Cloud SDK repo setup.
- [x] VS Code RPM repo setup.
- [x] WezTerm COPR enablement.
- [x] Ghostty COPR enablement fallback.
- [x] scrcpy COPR enablement fallback.
- [x] Default shell switch to `zsh` during config phase.
- [x] GNOME settings and shortcuts application.
- [x] GNOME favorite apps configuration.
