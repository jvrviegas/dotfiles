# Dotfiles Changelog

Notable package and configuration changes, grouped by date and deployment profile.
The package checklists describe current selections; this file records changes and why they were made.

Keep new entries under **Unreleased** until they are deployed, then move them to a
`YYYY-MM-DD` section. Use **Added**, **Removed**, and **Changed** only when needed.
For updates covering both packages and configuration, separate them under each profile.

## Unreleased

### Fedora GNOME

#### Added

- `xprop` (DNF): required by Pop Shell.

#### Changed

- Reviewed `FEDORA_PACKAGES_CHECKLIST.md`, treating all listed items as the
  previous selection baseline. Checked items remain selected; unchecked items
  below are excluded from the desired setup. These are selection changes, not
  confirmation that installer steps have been removed or installed packages
  uninstalled.
- Explicitly documented Pop Shell and its support packages: `pop-launcher`,
  `gnome-shell-extension-common`, and `xprop`.

#### Removed from selection

- **Terminals:** `alacritty` (DNF), `wezterm` (COPR).
- **Languages and runtimes:** `lua` and `dotnet-sdk-8.0` (DNF), `asdf`
  (Git clone), `nvm`, Node LTS, and `bun` (upstream scripts).
- **Containers:** `io.podman_desktop.PodmanDesktop` (Flatpak).
- **Networking:** `httpie` and `nmap` (DNF).
- **Apps:** `com.todoist.Todoist` (Flatpak).
- **Fonts:** Hack Nerd Font, FantasqueSansMono Nerd Font, and Maple Mono NF
  (manual downloads); JetBrainsMono Nerd Font remains selected.
- **GNOME themes:** WhiteSur GTK and icon themes (Git clones).
- **GNOME extensions:** Forge, Just Perfection, Vertical Workspaces, Open Bar,
  and Vicinae GNOME extension; Pop Shell remains selected for tiling.

Selection follow-ups before aligning the installer:

- WezTerm COPR setup is still checked despite WezTerm being deselected.
- `pnpm`, `markdownlint-cli`, and `tree-sitter-cli` remain selected while the
  Node LTS installation is deselected; they still need an available Node/npm
  runtime.
