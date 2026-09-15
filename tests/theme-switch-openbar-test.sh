#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$SCRIPT_DIR/.config/gnome/apply-openbar-theme.sh"
THEME_SWITCH="$SCRIPT_DIR/.local/bin/theme-switch"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_HOME="$TMP_DIR/home"
FAKE_BIN="$TMP_DIR/bin"
MAC_BIN="$TMP_DIR/mac-bin"
NO_DCONF_BIN="$TMP_DIR/no-dconf-bin"
FAKE_DCONF_LOG="$TMP_DIR/dconf.log"
FAKE_DCONF_TRIGGER="$TMP_DIR/trigger-reload"
FAKE_THEME_HOOK_LOG="$TMP_DIR/theme-hook.log"
ORIGINAL_PATH="$PATH"

mkdir -p \
  "$FAKE_HOME/.local/share/gnome-shell/extensions/openbar@neuromorph" \
  "$FAKE_BIN" \
  "$MAC_BIN" \
  "$NO_DCONF_BIN"

cat > "$FAKE_BIN/dconf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  write)
    [[ $# -eq 3 ]]
    printf '%s\t%s\n' "$2" "$3" >> "$FAKE_DCONF_LOG"
    if [[ "$2" == */trigger-reload ]]; then
      printf '%s\n' "$3" > "$FAKE_DCONF_TRIGGER"
    fi
    ;;
  read)
    [[ $# -eq 2 ]]
    if [[ -f "$FAKE_DCONF_TRIGGER" ]]; then
      cat "$FAKE_DCONF_TRIGGER"
    fi
    ;;
  *)
    printf 'unexpected dconf operation: %s\n' "${1:-}" >&2
    exit 2
    ;;
esac
EOF
chmod +x "$FAKE_BIN/dconf"

cat > "$MAC_BIN/uname" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' Darwin
EOF
chmod +x "$MAC_BIN/uname"

export HOME="$FAKE_HOME"
export PATH="$FAKE_BIN:$ORIGINAL_PATH"
export XDG_CURRENT_DESKTOP=GNOME
export FAKE_DCONF_LOG
export FAKE_DCONF_TRIGGER

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_log_contains() {
  local expected="$1"
  grep -Fqx -- "$expected" "$FAKE_DCONF_LOG" || \
    fail "dconf log did not contain: $expected"
}

# OB-01/OB-02: provisioning contains both the extensions.gnome.org mapping and UUID.
grep -Fqx '  "6580:openbar@neuromorph"' "$SCRIPT_DIR/linux-desktop/gnome.sh" || \
  fail 'GNOME_EXTENSIONS does not contain Open Bar'
grep -Fqx '  "openbar@neuromorph"' "$SCRIPT_DIR/linux-desktop/gnome.sh" || \
  fail 'GNOME_EXTENSION_UUIDS does not contain Open Bar'

# OB-04: each accepted theme produces a successful managed update.
themes=(
  the-mandalorian
  the-witcher
  monokai-pro
  hollow-knight
  red-dead-redemption-2
  darth-vader
  gruvbox
)
for theme in "${themes[@]}"; do
  : > "$FAKE_DCONF_LOG"
  "$HELPER" "$theme" >/dev/null || fail "accepted theme failed: $theme"
done

# OB-03/OB-06: contrasting palettes map to normalized Open Bar values, including
# low (0x0a/0x0f) and high (0xfe) channels, and each update triggers once.
: > "$FAKE_DCONF_LOG"
"$HELPER" the-mandalorian >/dev/null
assert_log_contains $'/org/gnome/shell/extensions/openbar/bgcolor\t[\'0.0392\', \'0.0392\', \'0.0588\']'
assert_log_contains $'/org/gnome/shell/extensions/openbar/dark-bgcolor\t[\'0.0392\', \'0.0392\', \'0.0588\']'
mandalorian_triggers="$(grep -Fc $'/org/gnome/shell/extensions/openbar/trigger-reload\t' "$FAKE_DCONF_LOG")"
[[ "$mandalorian_triggers" -eq 1 ]] || fail 'Mandalorian update did not trigger exactly once'

: > "$FAKE_DCONF_LOG"
"$HELPER" gruvbox >/dev/null
assert_log_contains $'/org/gnome/shell/extensions/openbar/mscolor\t[\'0.9961\', \'0.5020\', \'0.0980\']'
assert_log_contains $'/org/gnome/shell/extensions/openbar/dark-mscolor\t[\'0.9961\', \'0.5020\', \'0.0980\']'
assert_log_contains $'/org/gnome/shell/extensions/openbar/bcolor\t[\'0.2353\', \'0.2196\', \'0.2118\']'

grep -Fqx $'/org/gnome/shell/extensions/openbar/pause-reload\ttrue' "$FAKE_DCONF_LOG" || \
  fail 'Open Bar reload pause was not enabled before writes'
grep -Fqx $'/org/gnome/shell/extensions/openbar/pause-reload\tfalse' "$FAKE_DCONF_LOG" || \
  fail 'Open Bar reload pause was not cleared after writes'
gruvbox_triggers="$(grep -Fc $'/org/gnome/shell/extensions/openbar/trigger-reload\t' "$FAKE_DCONF_LOG")"
[[ "$gruvbox_triggers" -eq 1 ]] || fail 'Gruvbox update did not trigger exactly once'

# OB-09: invalid themes fail before any dconf write.
: > "$FAKE_DCONF_LOG"
if "$HELPER" not-a-theme >/dev/null 2>&1; then
  fail 'unknown theme unexpectedly succeeded'
fi
[[ ! -s "$FAKE_DCONF_LOG" ]] || fail 'unknown theme caused dconf writes'

# OB-09: an absent extension is a successful no-op.
rm -rf "$FAKE_HOME/.local/share/gnome-shell/extensions/openbar@neuromorph"
: > "$FAKE_DCONF_LOG"
"$HELPER" the-mandalorian >/dev/null || fail 'absent Open Bar was not a no-op'
[[ ! -s "$FAKE_DCONF_LOG" ]] || fail 'absent Open Bar caused dconf writes'
mkdir -p "$FAKE_HOME/.local/share/gnome-shell/extensions/openbar@neuromorph"

# OB-09: dconf is optional and its absence is a successful no-op.
cat > "$NO_DCONF_BIN/uname" <<'EOF'
#!/bin/bash
printf '%s\n' Linux
EOF
chmod +x "$NO_DCONF_BIN/uname"
: > "$FAKE_DCONF_LOG"
PATH="$NO_DCONF_BIN" /bin/bash "$HELPER" the-mandalorian >/dev/null || \
  fail 'missing dconf was not a no-op'
[[ ! -s "$FAKE_DCONF_LOG" ]] || fail 'missing dconf caused writes'

# OB-09: non-GNOME desktops do not call dconf.
export XDG_CURRENT_DESKTOP=XFCE
: > "$FAKE_DCONF_LOG"
"$HELPER" the-mandalorian >/dev/null || fail 'non-GNOME invocation failed'
[[ ! -s "$FAKE_DCONF_LOG" ]] || fail 'non-GNOME invocation called dconf'

# OB-09: macOS does not call dconf even if the desktop variable is misleading.
export XDG_CURRENT_DESKTOP=GNOME
PATH="$MAC_BIN:$FAKE_BIN:$ORIGINAL_PATH" "$HELPER" the-mandalorian >/dev/null || \
  fail 'macOS invocation failed'
[[ ! -s "$FAKE_DCONF_LOG" ]] || fail 'macOS invocation called dconf'

# OB-03: theme-switch passes the selected theme to the deployed helper once.
mkdir -p "$FAKE_HOME/.config/gnome"
cat > "$FAKE_HOME/.config/gnome/apply-openbar-theme.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$FAKE_THEME_HOOK_LOG"
EOF
chmod +x "$FAKE_HOME/.config/gnome/apply-openbar-theme.sh"
export FAKE_THEME_HOOK_LOG
: > "$FAKE_THEME_HOOK_LOG"
PATH="$FAKE_BIN:$ORIGINAL_PATH" XDG_CURRENT_DESKTOP=GNOME \
  "$THEME_SWITCH" gruvbox >/dev/null
[[ "$(cat "$FAKE_HOME/.config/theme/current")" == gruvbox ]] || \
  fail 'theme-switch did not persist the selected theme'
[[ "$(wc -l < "$FAKE_THEME_HOOK_LOG")" -eq 1 ]] || \
  fail 'theme-switch did not call Open Bar exactly once'
[[ "$(cat "$FAKE_THEME_HOOK_LOG")" == gruvbox ]] || \
  fail 'theme-switch passed the wrong theme to Open Bar'

printf 'PASS: theme-switch/Open Bar shell integration\n'
