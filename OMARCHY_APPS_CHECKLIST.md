# Omarchy application install checklist

Drafted from the macOS application lists in:

- `brew/formulae.sh`
- `brew/cask.sh`
- `brew/wm.sh`

Status was checked against this Omarchy machine (Omarchy `4.0.4-1`).

## Checklist conventions

- `[x]` — already installed; the future install script should skip it safely.
- `[ ]` under **Available but not installed** — check the apps that should be included in the install script.
- `[ ]` under **No native Linux version** — check once the proposed replacement or omission has been reviewed.
- Package names and installation methods will be confirmed when the script is created.

## Already installed on Omarchy

### CLI and development tools

- [x] GNU coreutils
- [x] OpenSSH
- [x] Git
- [x] GitHub CLI (`gh`, installed in `~/.local/bin`)
- [x] Neovim
- [x] fzf
- [x] eza
- [x] Starship
- [x] tmux
- [x] herdr
- [x] zoxide
- [x] fd
- [x] ripgrep
- [x] Lua
- [x] LuaJIT
- [x] LuaRocks
- [x] Docker Compose
- [x] jq
- [x] SQLite
- [x] FFmpeg
- [x] fmt
- [x] libsixel
- [x] mpv
- [x] Poppler
- [x] Tesseract (English data only)
- [x] tree-sitter CLI
- [x] Kanata
- [x] Claude Code (`~/.local/bin/claude`)

### Desktop applications and fonts

- [x] Google Chrome
- [x] Zen Browser
- [x] Ghostty
- [x] Docker Engine and Docker Compose (not Docker Desktop)
- [x] JetBrains Mono Nerd Font (basic package)

### Omarchy replacements already present

These are not the same macOS application, but their functionality is already provided by Omarchy.

- [x] Android File Transfer → GVfs MTP support
- [x] Karabiner-Elements → Kanata
- [x] Shottr → Omarchy screenshot tools (`grim`/selection capture)
- [x] Spaceman → Hyprland workspaces
- [x] AeroSpace / yabai / skhd → Hyprland
- [x] SketchyBar → Omarchy Shell bar
- [x] `switchaudio-osx` → PipeWire/WirePlumber audio controls

## Available on Linux but not installed

Check the items that should be installed by the future Omarchy script.

### CLI and development tools

- [ ] Vim
- [x] Lua Language Server
- [ ] NVM
- [x] Bun
- [x] Yarn
- [ ] asdf (Omarchy already includes `mise`, which may be preferable)
- [ ] .NET SDK (`dotnet-runtime` is installed, but the SDK is not)
- [x] OpenJDK 17
- [x] Rustup
- [ ] CocoaPods (can run on Linux, but iOS/Xcode workflows still require macOS)
- [ ] fastlane (Linux support is limited for Apple-specific workflows)
- [x] scrcpy
- [ ] Watchman
- [ ] FontForge
- [ ] OCRmyPDF
- [ ] Pandoc
- [ ] Additional Tesseract language data (macOS used `tesseract-lang`)
- [ ] markdownlint-cli
- [x] HTTPie
- [r] Nmap
- [x] pgpdump
- [ ] websocat
- [ ] Kanata Tray
- [ ] Neofetch (discontinued; Omarchy already includes Fastfetch)

### Browsers and terminals

- [ ] Microsoft Edge
- [x] Alacritty
- [ ] Kitty

### Development applications

- [x] Android platform tools (`adb`/`fastboot`)
- [ ] Android Studio
- [x] DBeaver Community
- [x] Google Cloud CLI
- [x] MongoDB Compass
- [x] Postman
- [x] Visual Studio Code
- [ ] Docker Desktop (Docker Engine and Compose are already installed)

### Communication, productivity, and media

- [x] Slack
- [ ] Todoist
- [x] Spotify

### Fonts

- [ ] Fantasque Sans Mono Nerd Font
- [ ] Hack Nerd Font
- [ ] Maple Mono
- [ ] Maple Mono NF

## No native Linux version (or not useful outside macOS)

These should not be installed as-is. Review whether to omit them or use the noted alternative.

### Apple and macOS development

- [ ] XcodeGen — requires Xcode/macOS; omit
- [ ] BasicTeX — macOS distribution; use a Linux TeX Live package if needed
- [ ] SF Mono — no official Linux distribution; omit or supply font files manually
- [ ] SF Pro — no official Linux distribution; omit or supply font files manually
- [ ] SF Symbols — Apple-only application; use a Linux icon set instead

### macOS-only applications and utilities

- [ ] OrbStack — use the already-installed Docker Engine/Compose
- [ ] Akiflow desktop app — use its web app
- [ ] Android File Transfer — functionality already covered by GVfs MTP
- [ ] AnkerWork — no official Linux client
- [ ] Karabiner-Elements — use the already-installed Kanata
- [ ] Raycast — use Omarchy's launcher or another Linux launcher
- [ ] Scroll Reverser — configure input behavior in Hyprland
- [ ] Shottr — use Omarchy's screenshot tools
- [ ] Spaceman — use Hyprland workspaces
- [ ] `switchaudio-osx` — use PipeWire/WirePlumber controls

### macOS window management

- [ ] AeroSpace — use Hyprland
- [ ] yabai — use Hyprland
- [ ] skhd — use Hyprland keybindings
- [ ] SketchyBar — use the Omarchy Shell bar

## Decisions before scripting

- [x] Select wanted items in **Available on Linux but not installed**
    Already selected
- [x] Decide whether to use `mise` instead of installing NVM and asdf.
yes, keep mise
- [ ] Decide whether the full .NET SDK is needed in addition to the installed runtime.
not necessary
- [ ] Select required Tesseract language packs.
not necessary
- [ ] Decide whether Docker Desktop is needed when Docker Engine is already installed.
not necessary
- [ ] Decide whether to keep Neofetch or use the already-installed Fastfetch.
keep fastfetch
- [ ] Review and acknowledge replacements/omissions in **No native Linux version**.
yes, already acknowledge
