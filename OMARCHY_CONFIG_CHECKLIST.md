# Omarchy `.config` and `.local` migration checklist

This checklist covers the repository's current `.config/` and `.local/` contents.
Use it to select what a future Omarchy-safe dotfiles installer should deploy.

## Checklist conventions

- `[ ]` — not selected for deployment.
- `[x]` — selected for deployment.
- **High impact** — can replace Omarchy behavior or disconnect automatic theme synchronization.
- **Conditional** — safe only when the related application/session is intentionally used.
- **Low impact** — does not normally affect Omarchy's desktop or theme system.
- Selecting a high-impact item means it must be **adapted for Omarchy**, not copied unchanged.

## Important finding

The current live Alacritty, Ghostty, and Kitty configs are unchanged Omarchy defaults. They import theme files from:

```text
~/.local/state/omarchy/current/theme/
```

Copying this repository's entire `.config/` directory would overwrite several of those files. The future installer should use an explicit allowlist instead of `cp -r .config "$HOME"`.

---

# `.config` checklist

## High impact: adapt or exclude

### Terminals and automatic theme synchronization

- [ ] **`.config/alacritty/`** — **High impact / breaks theme sync if copied unchanged**
  - Repository config imports the hardcoded `the-witcher.toml` theme.
  - Omarchy config imports `~/.local/state/omarchy/current/theme/alacritty.toml`.
  - Recommendation: preserve Omarchy's main `alacritty.toml`; port only non-theme preferences such as padding or opacity if wanted.

- [ ] **`.config/ghostty/`** — **High impact / breaks theme sync if copied unchanged**
  - Repository config sets `theme = the-witcher` and contains macOS-specific settings.
  - Omarchy config loads `~/.local/state/omarchy/current/theme/ghostty.conf`.
  - Recommendation: preserve Omarchy's main `config`; port only compatible keybindings and UI preferences.

- [ ] **`.config/kitty/`** — **High impact / breaks theme sync if copied unchanged**
  - Repository config includes a hardcoded Witcher theme.
  - Omarchy config includes `~/.local/state/omarchy/current/theme/kitty.conf`.
  - Recommendation: preserve Omarchy's main `kitty.conf`; port only non-color settings.

### Omarchy desktop behavior

- [ ] **`.config/hypr/`** — **High impact / can replace Omarchy Hyprland behavior and theme colors**
  - Contains an older standalone `hyprland.conf` with custom autostart, bindings, input, borders, Waybar, hyprpaper, and Vicinae.
  - Omarchy currently uses its Lua-based files under `~/.config/hypr/` and generated theme colors.
  - Recommendation: do not copy the directory. Port wanted bindings/input settings into Omarchy's current Lua files individually.

- [ ] **`.config/tmux/`** — **High impact / replaces Omarchy tmux behavior and color handling**
  - Repository config uses the separate `theme-switch` system and fixed theme scripts.
  - Current Omarchy tmux config uses terminal palette colors that follow Omarchy's terminal theme.
  - Recommendation: preserve Omarchy's config and port only wanted keybindings/session behavior.
  - Note: root `.tmux.conf` is outside this checklist but presents the same conflict.

- [ ] **`.config/xdg-desktop-portal/`** — **High impact / changes screen sharing and file-picker portal selection**
  - Forces `hyprland;gtk` portal preference.
  - Recommendation: preserve Omarchy's portal setup unless a specific portal problem requires this override.

- [ ] **`.config/quickshell/`** — **High impact if launched / alternative shell and bar**
  - Contains a standalone Quickshell bar with its own static `Theme.qml`.
  - It is separate from Omarchy Shell and will not follow Omarchy's plugin/theme system automatically.
  - Recommendation: exclude unless intentionally replacing Omarchy Shell.

- [ ] **`.config/caelestia/`** — **High impact if launched / alternative shell configuration**
  - Can introduce a second desktop shell configuration outside Omarchy Shell.
  - Recommendation: exclude unless intentionally using Caelestia instead of Omarchy Shell.

- [ ] **`.config/waybar/`** — **High impact if launched / alternative bar**
  - Static Waybar config and colors do not automatically follow Omarchy themes.
  - Recommendation: exclude while using Omarchy Shell.

### Shell and independent theme system

- [x] **`.config/zsh/`** — **Conditional / changes shell startup and theme behavior**
  - Enables a custom Starship config, Zap, NVM/asdf compatibility, aliases, and macOS/Linux PATH logic.
  - `STARSHIP_CONFIG=~/.config/starship/starship.toml` bypasses Omarchy's normal `~/.config/starship.toml` location.
  - Includes the old `colorscheme-set.sh` theme system.
  - Recommendation: port shell aliases and functions, but remove old theme/NVM/asdf integration and use mise.
  - Note: it only becomes the active Zsh configuration when the root `.zshenv` sets `ZDOTDIR`.

- [x] **`.config/starship/`** — **Conditional / static theme, no Omarchy auto-sync**
  - Used by the repository's Zsh configuration through `STARSHIP_CONFIG`.
  - Does not overwrite Omarchy's normal `~/.config/starship.toml`, but its colors remain independent.
  - Recommendation: exclude or adapt to use terminal palette colors.

- [ ] **`.config/herdr/`** — **Conditional / replaces current Herdr behavior and uses the old theme system**
  - Repository config contains a hardcoded Witcher theme block managed by `theme-switch`.
  - Current config uses the terminal palette and therefore follows terminal theme changes more naturally.
  - Recommendation: preserve the current config and port only wanted Herdr keybindings/UI settings.

## Conditional application configs

These do not alter Omarchy by themselves, but may change the named application or introduce an alternative desktop component.

- [x] **`.config/kanata/`** — **Conditional / changes keyboard layout globally**
  - Contains the Colemak-DH mapping.
  - Can significantly change keyboard behavior but does not affect theme synchronization.
  - Recommendation: deploy only if this exact keyboard mapping is wanted.

- [ ] **`.config/vicinae/`** — **Conditional / alternative launcher behavior**
  - Configures Vicinae as a Raycast-like launcher.
  - Does not auto-sync with Omarchy themes and may duplicate Omarchy's launcher.

- [ ] **`.config/wezterm/`** — **Conditional / terminal not managed by Omarchy theme sync**
  - Contains static WezTerm themes and settings.
  - Omarchy's built-in terminal theme templates cover Alacritty, Foot, Ghostty, and Kitty—not WezTerm.

- [ ] **`.config/gnome/`** — **Conditional / GNOME only**
  - GNOME extension settings and an independent Open Bar theme script.
  - Normally inactive in an Omarchy Hyprland session.

- [ ] **`.config/aerospace/`** — **Conditional / macOS only**
  - No effect on Linux unless processed by another script.

- [ ] **`.config/sketchybar/`** — **Conditional / macOS only**
  - Uses the repository's independent theme selection file.
  - No effect on Omarchy unless its scripts are invoked manually.

- [ ] **`.config/skhd/`** — **Conditional / macOS only**
  - No effect on Linux.

- [ ] **`.config/yabai/`** — **Conditional / macOS only**
  - No effect on Linux.

## Low-impact configs and data

- [x] **`.config/git/`** — **Low impact**
  - Contains the global Git ignore file.
  - Does not affect Omarchy desktop behavior or theme synchronization.

- [ ] **`.config/wallpapers/`** — **Low impact by itself**
  - Repository wallpaper collection.
  - Omarchy will not automatically use this directory.
  - To integrate safely, selected images should be copied to `~/.config/omarchy/backgrounds/<theme>/` or a custom Omarchy theme.

---

# `.local` checklist

## High impact: adapt or exclude

- [ ] **`.local/bin/theme-switch`** — **High impact / conflicts with Omarchy theme synchronization**
  - Directly rewrites Ghostty, Kitty, Alacritty, Neovim, tmux, Herdr, Starship, and wallpaper settings.
  - Uses a separate theme state at `~/.config/theme/current`.
  - Recommendation: do not deploy on Omarchy. Use `omarchy theme set` instead.

- [ ] **`.local/bin/reload-touchpad`** — **High impact / hardware-specific root operation**
  - Uses `sudo` to unload and reload I2C-HID kernel modules.
  - Recommendation: deploy only on hardware that needs this recovery command.

- [ ] **`.local/share/applications/vicinae.desktop`** — **Conditional / changes launcher behavior**
  - Overrides Vicinae's desktop entry to talk to an existing Vicinae service.
  - Only deploy if Vicinae is intentionally installed and managed as a service.

## Portable development helpers

These do not change Omarchy configuration or theme synchronization.

- [ ] **`.local/bin/android-emulator.sh`** — launches an Android emulator; supports Linux and macOS SDK paths.
- [ ] **`.local/bin/checkPort.sh`** — port-check helper.
- [ ] **`.local/bin/classComponentChecker.sh`** — development helper.
- [ ] **`.local/bin/diff-highlight`** — Git diff highlighting helper.
- [ ] **`.local/bin/rnGenerateCleanAndroidApk.sh`** — React Native/Android build helper.

## Herdr helpers

These affect Herdr sessions only and do not modify Omarchy themes.

- [ ] **`.local/bin/herdr-cht.sh`** — cheat-sheet lookup helper.
- [x] **`.local/bin/herdr-sessionizer`** — project picker and Herdr workspace launcher.

## tmux helpers

These affect tmux sessions but do not overwrite Omarchy configuration by themselves.

- [ ] **`.local/bin/tmux-cht.sh`** — cheat-sheet lookup helper.
- [ ] **`.local/bin/tmux-create-dev-windows`** — creates development windows.
- [ ] **`.local/bin/tmux-notes-sessionizer`** — opens notes in a tmux session.
- [ ] **`.local/bin/tmux-sessionizer`** — project picker and tmux session launcher.
- [ ] **`.local/bin/tmux-start`** — starts a session named after the current directory.

## macOS-only helpers

These have no useful Omarchy behavior and should normally be omitted.

- [ ] **`.local/bin/skhd-doctor`** — diagnoses the macOS `skhd` service and Secure Keyboard Entry.
- [ ] **`.local/bin/wallpaper-all-spaces`** — changes wallpaper across macOS Mission Control spaces.

---

# Migration decisions

- [x] Select the `.config` directories or individual settings to preserve.
- [x] Select portable `.local/bin` helpers.
- [x] Keep Omarchy's live Alacritty, Ghostty, and Kitty base configs.
- [x] Keep Omarchy's current Hyprland Lua configuration and port changes individually.
- [x] Keep Omarchy Shell instead of deploying Quickshell, Caelestia, or Waybar alternatives.
- [ ] Replace the repository's `theme-switch` workflow with `omarchy theme set`.
      The theme-switch will be kept for macos and fedora, on omarchy will not be included
- [x] Decide whether to use Zsh while retaining mise and Omarchy-compatible theme behavior.
yes, zsh retaining mise
- [x] Decide whether Colemak-DH Kanata mapping should be deployed.
yes, it needs to install kanata, configure the service and configure with Colemak-DH
- [x] Build the future installer from an allowlist; never recursively copy all of `.config/` or `.local/`.
