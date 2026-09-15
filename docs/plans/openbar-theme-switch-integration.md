# Open Bar + `theme-switch` Integration Plan

**Status:** Planned — not started  
**Owner:** Next implementation agent  
**Last updated:** 2026-06-18

## Objective

Install and configure the Open Bar GNOME Shell extension and make its appearance follow the theme selected by `~/.local/bin/theme-switch`, using the same palettes already used by SketchyBar.

The desired GNOME top bar should resemble the current SketchyBar design: a floating, rounded, dark translucent bar with theme-specific foreground, border, hover, selection, and popup-menu colors.

## Repository context

- Theme selector: `.local/bin/theme-switch`
- Selected-theme state: `~/.config/theme/current`
- Canonical theme names and palettes: `.config/sketchybar/themes/*.lua`
- SketchyBar geometry: `.config/sketchybar/bar.lua`
- SketchyBar component styling: `.config/sketchybar/default.lua`
- GNOME extension setup: `linux-desktop/gnome.sh`
- Restored GNOME extension settings: `.config/gnome/extensions/*.dconf`
- Open Bar extension UUID: `openbar@neuromorph`
- extensions.gnome.org ID: `6580`
- Open Bar dconf path: `/org/gnome/shell/extensions/openbar/`

Most configuration is copied to `$HOME` by the installation scripts. Do not assume files outside symlinked directories update live.

## Safety constraints

- [ ] Preserve all unrelated working-tree modifications.
- [ ] In particular, `linux-desktop/gnome.sh` already has uncommitted keyboard-shortcut changes. Make targeted edits only.
- [ ] Do not change existing SketchyBar palettes or theme behavior.
- [ ] Open Bar integration must safely no-op on macOS, non-GNOME Linux desktops, and systems where Open Bar is not installed.
- [ ] Do not enable Open Bar wallpaper auto-theming; `theme-switch` remains the source of truth.
- [ ] Do not commit unless explicitly requested.

## Requirements

| ID | Requirement | Verification |
|---|---|---|
| OB-01 | GNOME setup installs Open Bar through the existing `gext` flow. | `GNOME_EXTENSIONS` contains `6580:openbar@neuromorph`. |
| OB-02 | GNOME setup persists Open Bar in the enabled extension UUID list. | `GNOME_EXTENSION_UUIDS` contains `openbar@neuromorph`. |
| OB-03 | Running `theme-switch <theme>` on GNOME applies that theme to Open Bar. | Compare relevant dconf values before/after switching between two themes. |
| OB-04 | All seven themes supported by `theme-switch` have Open Bar mappings. | Automated loop validates every accepted theme name. |
| OB-05 | Bar geometry approximates current SketchyBar geometry. | Open Bar uses Floating, Top, height 36, margin 8, radius 14. |
| OB-06 | Bar and menus use the selected theme's existing palette semantics. | Values match the palette table below. |
| OB-07 | Theme changes trigger an Open Bar stylesheet refresh without requiring a logout. | Visual/manual switch test; refresh trigger changes after writes. |
| OB-08 | Setup applies the currently selected theme after installing/restoring GNOME extensions. | Fresh-setup path invokes the helper with `~/.config/theme/current`. |
| OB-09 | Unsupported environments and absent Open Bar installations do not make `theme-switch` fail. | Shell tests with missing commands/directories exit successfully. |
| OB-10 | Existing GNOME extension configuration remains intact. | Review targeted diff and run shell syntax checks. |

## Palette mapping

Use the existing SketchyBar semantic colors rather than Open Bar's wallpaper-generated palette.

| Theme | Background (`black`) | Foreground (`white`) | Border (`bar.border`) | Hover (`secondary`) | Active (`primary`) | Menu border (`popup.border`) |
|---|---:|---:|---:|---:|---:|---:|
| `the-mandalorian` | `#0a0a0f` | `#e4e4ec` | `#20202b` | `#5ec4e8` | `#e8c070` | `#2d2d3a` |
| `the-witcher` | `#0b0f12` | `#d8d3c5` | `#1b2428` | `#7f9aa3` | `#d89a2b` | `#2a363b` |
| `monokai-pro` | `#19181a` | `#fcfcfa` | `#2d2a2e` | `#ab9df2` | `#a9dc76` | `#5b595c` |
| `hollow-knight` | `#0d0d14` | `#f0f0f8` | `#1a1a24` | `#f4c542` | `#85c1e9` | `#3a3a4a` |
| `red-dead-redemption-2` | `#1a1410` | `#e4d8c2` | `#2d221a` | `#8a9ca8` | `#c4732e` | `#3d3229` |
| `darth-vader` | `#08080a` | `#d8d8dc` | `#16161c` | `#7ee6e6` | `#d43a3a` | `#26262e` |
| `gruvbox` | `#1d2021` | `#ebdbb2` | `#3c3836` | `#8ec07c` | `#fe8019` | `#504945` |

Palette sources are `.config/sketchybar/themes/*.lua`. If those sources differ from this table at implementation time, treat the Lua files as authoritative and update this table.

## Proposed design

### Dedicated GNOME helper

Create `.config/gnome/apply-openbar-theme.sh` as the only component that knows Open Bar's dconf keys. It should:

1. Accept exactly one theme name.
2. Validate it against the same seven names accepted by `theme-switch`.
3. Exit successfully without changes when not running under GNOME, `dconf` is unavailable, or `openbar@neuromorph` is not installed in either:
   - `$HOME/.local/share/gnome-shell/extensions/openbar@neuromorph`
   - `/usr/share/gnome-shell/extensions/openbar@neuromorph`
4. Map the selected theme to six-digit RGB hex values.
5. Convert each hex color to Open Bar's `as` GVariant format, where channels are decimal values from `0.0` to `1.0`, e.g. `#0a0a0f` becomes approximately `['0.0392', '0.0392', '0.0588']`.
6. Write values under `/org/gnome/shell/extensions/openbar/` with `dconf write`.
7. Trigger one stylesheet reload after all values have been written.

Prefer `dconf write` over plain `gsettings set`: a per-user GNOME extension schema may not be in the command-line process's default schema search path. If the implementation instead uses `gsettings`, it must locate the extension schema and pass the correct `--schemadir`; verify this on an installed system.

### Theme-switch hook

After wallpaper selection in `.local/bin/theme-switch`, or in a clearly named GNOME section:

- Detect GNOME consistently with the script's existing wallpaper branch.
- If `$HOME/.config/gnome/apply-openbar-theme.sh` is executable, invoke it with `$THEME`.
- Keep failures non-fatal only for the expected “extension unavailable” case. Invalid mappings or malformed values should be visible during development/testing.

### GNOME setup hook

In `linux-desktop/gnome.sh`:

- Add Open Bar to both extension arrays.
- Ensure `.config/gnome/apply-openbar-theme.sh` is executable in the repository and after deployment.
- Near the end of GNOME extension configuration, read `$HOME/.config/theme/current`, falling back to `the-mandalorian`, and invoke the helper if present.
- A newly installed extension may still require logout/login on Wayland; retain the existing user-facing message.

## Initial Open Bar settings

Verify every key against the installed Open Bar schema or the current upstream schema before implementation. Open Bar main currently supports GNOME 45+.

### Static geometry and behavior

| Key | Proposed value | Rationale |
|---|---:|---|
| `bartype` | `'Floating'` | Closest match to the single SketchyBar surface. |
| `position` | `'Top'` | Match current bar placement. |
| `height` | `36.0` | Matches `.config/sketchybar/bar.lua`. |
| `margin` | `8.0` | Matches SketchyBar's margin. |
| `bradius` | `14.0` | Matches SketchyBar's corner radius. |
| `bwidth` | `0.0` | Exact current SketchyBar config; color remains mapped for future tuning. |
| `gradient` | `false` | Current bar uses one background color. |
| `neon` | `false` | Current design has no neon border. |
| `shadow` | `true` | Approximate SketchyBar's soft floating depth. |
| `shcolor` | black | Neutral shadow. |
| `shalpha` | `0.20` | Keep shadow subtle. |
| `hpad` | `3.0` | Approximate existing item padding. |
| `vpad` | `3.0` | Preserve compact bar contents. |
| `heffect` | `true` | Rounded hover feedback for panel indicators. |
| `menustyle` | `true` | Style GNOME panel menus consistently. |
| `menu-radius` | `14.0` | Matches SketchyBar popups. |
| `autotheme-refresh` | `false` | Prevent wallpaper auto-theme from overriding `theme-switch`. |
| `autofg-bar` | `false` | Use explicit theme foreground. |
| `autofg-menu` | `false` | Use explicit theme foreground. |
| `wmaxbar` | `false` | Keep theme stable when windows maximize. |

Do not style all GTK/Flatpak apps or all shell surfaces by default. Keep `apply-menu-shell`, `apply-accent-shell`, and `apply-all-shell` false unless manual validation proves this is desired.

### Dynamic colors

Apply both the base key and `dark-` counterpart where Open Bar stores dark/light values separately. GNOME is currently configured with `prefer-dark`.

| Purpose | Open Bar keys | Source | Alpha |
|---|---|---|---:|
| Bar text/icons | `fgcolor`, `dark-fgcolor` | `white` | `fgalpha=1.0` |
| Bar surface | `bgcolor`, `dark-bgcolor` | `black` | `bgalpha=0.85` (`0xd9`) |
| Panel-box transparency | `boxcolor`, `dark-boxcolor` | `black` | `boxalpha=0.0` |
| Border | `bcolor`, `dark-bcolor` | `bar.border` | `balpha=1.0` |
| Hover/focus | `hcolor`, `dark-hcolor` | `secondary` | `halpha=0.22` |
| Menu text/icons | `mfgcolor`, `dark-mfgcolor` | `white` | `mfgalpha=1.0` |
| Menu surface | `mbgcolor`, `dark-mbgcolor` | `black` | `mbgalpha=0.90` (`0xe6`) |
| Menu border | `mbcolor`, `dark-mbcolor` | `popup.border` | `mbalpha=0.65` |
| Menu hover | `mhcolor`, `dark-mhcolor` | `secondary` | `mhalpha=0.22` |
| Menu active/selected | `mscolor`, `dark-mscolor` | `primary` | `msalpha=0.85` |
| Accent override | `accent-color`, `dark-accent-color` | `primary` | Set `accent-override=true` only if required for manual color application. |

Avoid writing `light-*` keys unless light-mode behavior is intentionally designed. All repository themes are dark themes.

## Implementation tasks

### T1 — Add Open Bar to GNOME provisioning

**Files:** `linux-desktop/gnome.sh`  
**Requirements:** OB-01, OB-02, OB-08, OB-10  
**Depends on:** none

- [ ] Add `6580:openbar@neuromorph` to `GNOME_EXTENSIONS`.
- [ ] Add `openbar@neuromorph` to `GNOME_EXTENSION_UUIDS`.
- [ ] Add a final current-theme application hook.
- [ ] Preserve existing uncommitted keybinding changes.
- [ ] Confirm the existing `gext` compatibility behavior remains unchanged.

**Done when:** targeted diff contains only the Open Bar additions plus pre-existing unrelated changes.

### T2 — Implement the Open Bar theme helper

**Files:** `.config/gnome/apply-openbar-theme.sh` (new)  
**Requirements:** OB-03 through OB-07, OB-09  
**Depends on:** none

- [ ] Add strict argument validation and clear usage/error text.
- [ ] Add all seven palette mappings.
- [ ] Add environment/installation guards.
- [ ] Implement deterministic hex-to-GVariant conversion.
- [ ] Apply static geometry/behavior settings.
- [ ] Apply dynamic base and dark-mode color settings.
- [ ] Disable Open Bar auto-theme refresh.
- [ ] Batch writes with `pause-reload=true` if supported, then set it false and toggle `trigger-reload` once. Confirm expected trigger semantics from Open Bar's current source before relying on them.
- [ ] Mark the helper executable.

**Done when:** every supported theme produces valid writes and an unsupported theme exits non-zero without changing dconf.

### T3 — Connect `theme-switch` to Open Bar

**Files:** `.local/bin/theme-switch`  
**Requirements:** OB-03, OB-09  
**Depends on:** T2

- [ ] Add a GNOME-only Open Bar section.
- [ ] Invoke `$HOME/.config/gnome/apply-openbar-theme.sh "$THEME"` when available.
- [ ] Preserve existing macOS SketchyBar reload behavior.
- [ ] Preserve current wallpaper, terminal, Neovim, tmux, Pi, and Herdr behavior.

**Done when:** a theme switch updates `~/.config/theme/current` and calls the Open Bar helper exactly once on GNOME.

### T4 — Add automated shell-level tests

**Files:** Prefer `tests/theme-switch-openbar-test.sh` or follow any testing convention discovered at implementation time.  
**Requirements:** OB-04, OB-09, OB-10  
**Depends on:** T2, T3

Use temporary fake `HOME`, `PATH`, `dconf`, and GNOME extension directories; do not mutate the developer's real dconf database in automated tests.

- [ ] Assert all seven theme names are accepted.
- [ ] Assert expected colors are emitted for at least two contrasting themes.
- [ ] Assert normalized RGB conversion is correct for low and high channel values.
- [ ] Assert unknown theme fails without writes.
- [ ] Assert absent Open Bar exits successfully without writes.
- [ ] Assert non-GNOME/macOS invocation does not call dconf.
- [ ] Assert the theme-switch hook passes the selected theme once.

**Done when:** tests pass without GNOME Shell or Open Bar installed.

### T5 — Validate on GNOME

**Requirements:** all  
**Depends on:** T1–T4

- [ ] Install/enable Open Bar through `linux-desktop/gnome.sh` or `gext`.
- [ ] Log out/in if required by Wayland.
- [ ] Run `theme-switch the-mandalorian`.
- [ ] Confirm floating geometry, colors, hover state, and popup menus visually.
- [ ] Run `theme-switch gruvbox` and confirm live color changes without logout.
- [ ] Run one theme with a different accent, e.g. `darth-vader`, to confirm active/hover mappings are not hard-coded.
- [ ] Confirm Vitals, coding-agent indicator, GSConnect, Earport, clock/calendar, and Quick Settings remain usable.
- [ ] Check for styling conflicts with Blur My Shell. If panel blur visibly conflicts, change only the Blur My Shell panel setting needed to resolve it and document the reason; do not disable unrelated blur effects.
- [ ] Confirm `theme-switch` still works on macOS or via mocked platform test.

**Done when:** all acceptance checks below pass.

## Validation commands

Run from the repository root:

```bash
bash -n .local/bin/theme-switch
bash -n .config/gnome/apply-openbar-theme.sh
bash -n linux-desktop/gnome.sh
```

If ShellCheck is installed:

```bash
shellcheck .local/bin/theme-switch \
  .config/gnome/apply-openbar-theme.sh \
  linux-desktop/gnome.sh
```

Inspect values on GNOME:

```bash
dconf dump /org/gnome/shell/extensions/openbar/
gnome-extensions info openbar@neuromorph
gnome-extensions list --enabled | grep -Fx openbar@neuromorph
```

Review scope before completion:

```bash
git diff --check
git diff -- .local/bin/theme-switch \
  .config/gnome/apply-openbar-theme.sh \
  linux-desktop/gnome.sh
git status --short
```

## Acceptance checklist

- [ ] Open Bar is provisioned and enabled by GNOME setup.
- [ ] Current theme is applied during GNOME setup.
- [ ] Every `theme-switch` theme maps to Open Bar.
- [ ] Switching themes updates the GNOME top bar live.
- [ ] Selected theme state remains `~/.config/theme/current`.
- [ ] Open Bar auto-theming cannot overwrite manually mapped colors.
- [ ] Bar geometry matches the 36px floating SketchyBar design.
- [ ] GNOME panel extensions remain functional and legible.
- [ ] macOS behavior remains unchanged.
- [ ] Automated tests and shell syntax checks pass.
- [ ] No unrelated working-tree changes were overwritten.

## Known risks and mitigations

1. **Extension schema unavailable to CLI `gsettings`:** use `dconf write`, or explicitly provide the installed schema directory.
2. **Open Bar setting names change between releases:** verify against the installed schema and current upstream `org.gnome.shell.extensions.openbar.gschema.xml` before writing keys.
3. **Too many live stylesheet rebuilds:** pause reloads while writing and trigger exactly one refresh after the batch.
4. **Open Bar and Blur My Shell both style the panel:** manually test; adjust only Blur My Shell's panel-specific behavior if necessary.
5. **Third-party indicators bypass standard GNOME panel APIs:** verify each existing indicator visually; do not rewrite those extensions as part of this task.
6. **User changes Open Bar manually:** the next `theme-switch` intentionally restores managed values. Document this behavior in helper comments.
7. **Install-time copy model:** ensure the new helper reaches `$HOME/.config/gnome/` when testing; repository edits alone may not affect an already-installed Linux environment.

## Out of scope

- Replacing GNOME's panel or implementing arbitrary SketchyBar widgets.
- Modifying the seven canonical theme palettes.
- Adding new themes.
- Styling all GTK/Flatpak applications.
- Reconfiguring existing GNOME indicator extensions beyond compatibility fixes proven necessary during manual validation.
- Refactoring the broader theme system.

## Handoff notes

Start by checking `git status` and `git diff -- linux-desktop/gnome.sh`; there are pre-existing uncommitted changes that belong to the user. Use targeted edits.

Before implementing Open Bar keys, inspect either the installed schema or current upstream schema:

```bash
OPENBAR_DIR="$HOME/.local/share/gnome-shell/extensions/openbar@neuromorph"
rg '<key .*name=' "$OPENBAR_DIR/schemas/org.gnome.shell.extensions.openbar.gschema.xml"
```

Upstream reference: <https://github.com/neuromorph/openbar>.
