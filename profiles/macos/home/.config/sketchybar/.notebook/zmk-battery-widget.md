# ZMK battery widget

Tags: sketchybar, zmk, keyboard, bluetooth

`items/widgets/zmk_battery.lua` renders `widgets.zmk_battery` from `~/.local/state/zmk-battery/battery.json`, written by LaunchAgent `com.zmk.batterydaemon` (`~/.local/bin/ZMKBatteryDaemon`).

Connection state uses two sources:
- daemon JSON for battery levels, daemon-reported `connected`, and `device_name`
- `system_profiler SPBluetoothDataType` to verify whether vendor `0x1D50` keyboard is under `Connected` vs `Not Connected`

Daemon source lives at `/Users/joaoviegas/Projects/Personal/keyboard/zmk-integration`. The daemon used to hardcode `targetDeviceName = "TOTEM"` and notification title `"TOTEM Battery Low"`; with both TOTEM and Corne paired/connected in CoreBluetooth, it kept monitoring/notifying for TOTEM while the UI/parser could identify Corne. Fixed source prioritizes `ZMK_BATTERY_TARGET_NAMES` or default `Corne-JVVR,TOTEM`, writes `device_name` to JSON, and uses dynamic notification title.

Gotcha: repo default `default.lua` sets `updates = "when_shown"`. Hidden items do not receive routine updates, so a widget hidden while disconnected cannot unhide itself when the keyboard reconnects. `widgets.zmk_battery` must set `updates = true` with `update_freq = 30`.

Daemon implementation: `Sources/ZMKBatteryShared/BLEManager.swift` uses CoreBluetooth to connect to one matching ZMK peripheral (`ZMK_BATTERY_TARGET_NAMES`, default `Corne-JVVR,TOTEM`), discovers Battery Service `180F`, reads/subscribes to each Battery Level characteristic `2A19`, reads User Description descriptors `2901` for labels, then writes sorted `levels`/`labels` to JSON. It does not connect to each split half as separate Bluetooth devices; multiple half readings only appear if the connected ZMK peripheral exposes multiple battery characteristics.

Refresh button in popup kickstarts `gui/$(id -u)/com.zmk.batterydaemon`, waits briefly, then redraws bar and popup.
