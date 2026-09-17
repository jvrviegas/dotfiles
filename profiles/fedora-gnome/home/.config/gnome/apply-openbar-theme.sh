#!/usr/bin/env bash

# Apply one of the repository's canonical palettes to Open Bar.
# Open Bar is managed by theme-switch; manual Open Bar changes are therefore
# intentionally restored the next time a theme is selected.
set -euo pipefail
export LC_ALL=C

OPENBAR_PATH="/org/gnome/shell/extensions/openbar"
OPENBAR_LOCAL_DIR="$HOME/.local/share/gnome-shell/extensions/openbar@neuromorph"
OPENBAR_SYSTEM_DIR="/usr/share/gnome-shell/extensions/openbar@neuromorph"

usage() {
  printf 'Usage: %s <theme>\n' "${0##*/}" >&2
  printf 'Themes: the-mandalorian the-witcher monokai-pro hollow-knight ' >&2
  printf 'red-dead-redemption-2 darth-vader gruvbox\n' >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

THEME="$1"
case "$THEME" in
  the-mandalorian)
    black="0a0a0f"
    white="e4e4ec"
    border="20202b"
    secondary="5ec4e8"
    primary="e8c070"
    menu_border="2d2d3a"
    ;;
  the-witcher)
    black="0b0f12"
    white="d8d3c5"
    border="1b2428"
    secondary="7f9aa3"
    primary="d89a2b"
    menu_border="2a363b"
    ;;
  monokai-pro)
    black="19181a"
    white="fcfcfa"
    border="2d2a2e"
    secondary="ab9df2"
    primary="a9dc76"
    menu_border="5b595c"
    ;;
  hollow-knight)
    black="0d0d14"
    white="f0f0f8"
    border="1a1a24"
    secondary="f4c542"
    primary="85c1e9"
    menu_border="3a3a4a"
    ;;
  red-dead-redemption-2)
    black="1a1410"
    white="e4d8c2"
    border="2d221a"
    secondary="8a9ca8"
    primary="c4732e"
    menu_border="3d3229"
    ;;
  darth-vader)
    black="08080a"
    white="d8d8dc"
    border="16161c"
    secondary="7ee6e6"
    primary="d43a3a"
    menu_border="26262e"
    ;;
  gruvbox)
    black="1d2021"
    white="ebdbb2"
    border="3c3836"
    secondary="8ec07c"
    primary="fe8019"
    menu_border="504945"
    ;;
  *)
    printf 'Unknown theme: %s\n' "$THEME" >&2
    usage
    exit 2
    ;;
esac

# Match theme-switch's GNOME detection, while explicitly excluding macOS and
# other desktops before looking for dconf or touching any Open Bar settings.
DESKTOP="${XDG_CURRENT_DESKTOP:-}"
OS_NAME="$(uname -s 2>/dev/null || true)"
if [[ "$OS_NAME" != "Linux" || "${DESKTOP,,}" != *gnome* ]]; then
  exit 0
fi

# Open Bar is optional. These guards make theme-switch safe before installation,
# when dconf is unavailable, and on GNOME sessions without the extension.
if ! command -v dconf >/dev/null 2>&1; then
  exit 0
fi
if [[ ! -d "$OPENBAR_LOCAL_DIR" && ! -d "$OPENBAR_SYSTEM_DIR" ]]; then
  exit 0
fi

rgb_component() {
  local component="$1"
  local value scaled

  value=$((16#$component))
  scaled=$(( (value * 10000 + 127) / 255 ))
  if (( scaled >= 10000 )); then
    printf '1.0000'
  else
    printf '0.%04d' "$scaled"
  fi
}

hex_to_gvariant() {
  local hex="${1#\#}"

  if [[ ! "$hex" =~ ^[0-9a-fA-F]{6}$ ]]; then
    printf 'Invalid Open Bar color: %s\n' "$1" >&2
    return 1
  fi

  printf "['%s', '%s', '%s']" \
    "$(rgb_component "${hex:0:2}")" \
    "$(rgb_component "${hex:2:2}")" \
    "$(rgb_component "${hex:4:2}")"
}

write_setting() {
  dconf write "$OPENBAR_PATH/$1" "$2"
}

write_color_pair() {
  local key="$1"
  local color="$2"
  local value

  value="$(hex_to_gvariant "$color")"
  write_setting "$key" "$value"
  write_setting "dark-$key" "$value"
}

# Keep Open Bar from rebuilding its stylesheet for every individual setting.
# The current upstream schema exposes these two boolean controls, and the
# extension reloads when trigger-reload changes.
reload_paused=false
clear_reload_pause() {
  if [[ "$reload_paused" == true ]]; then
    dconf write "$OPENBAR_PATH/pause-reload" false || true
    reload_paused=false
  fi
}
trap clear_reload_pause EXIT

write_setting pause-reload true
reload_paused=true

# Static geometry and behavior matching the SketchyBar configuration.
write_setting bartype "'Floating'"
write_setting position "'Top'"
write_setting height 36.0
write_setting margin 8.0
write_setting bradius 14.0
write_setting bwidth 0.0
write_setting gradient false
write_setting neon false
write_setting shadow true
write_setting shalpha 0.20
write_setting hpad 3.0
write_setting vpad 3.0
write_setting heffect true
write_setting menustyle true
write_setting menu-radius 14.0
write_setting autotheme-refresh false
write_setting autofg-bar false
write_setting autofg-menu false
write_setting wmaxbar false
write_setting apply-menu-shell false
write_setting apply-accent-shell false
write_setting apply-all-shell false
write_setting accent-override false

# Explicit theme colors. Base and dark values are kept in sync because GNOME
# is configured with prefer-dark; light-* values are intentionally untouched.
write_color_pair fgcolor "$white"
write_setting fgalpha 1.0
write_color_pair bgcolor "$black"
write_setting bgalpha 0.85
write_color_pair boxcolor "$black"
write_setting boxalpha 0.0
write_color_pair bcolor "$border"
write_setting balpha 1.0
write_color_pair shcolor "$black"
write_color_pair hcolor "$secondary"
write_setting halpha 0.22
write_color_pair mfgcolor "$white"
write_setting mfgalpha 1.0
write_color_pair mbgcolor "$black"
write_setting mbgalpha 0.90
write_color_pair mbcolor "$menu_border"
write_setting mbalpha 0.65
write_color_pair mhcolor "$secondary"
write_setting mhalpha 0.22
write_color_pair mscolor "$primary"
write_setting msalpha 0.85

# Keep the accent override disabled: Open Bar uses mscolor for menu selection,
# while these values remain available if shell accent styling is enabled later.
write_color_pair accent-color "$primary"

write_setting pause-reload false
reload_paused=false

trigger_value="$(dconf read "$OPENBAR_PATH/trigger-reload")"
case "$trigger_value" in
  true)
    next_trigger=false
    ;;
  false|"")
    next_trigger=true
    ;;
  *)
    printf 'Unexpected Open Bar trigger-reload value: %s\n' "$trigger_value" >&2
    exit 1
    ;;
esac
write_setting trigger-reload "$next_trigger"

trap - EXIT
printf 'Applied Open Bar theme: %s\n' "$THEME"
