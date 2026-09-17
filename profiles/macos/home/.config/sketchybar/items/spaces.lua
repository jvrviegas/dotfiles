-- Auto-detect running window manager and load the appropriate spaces config
local handle = io.popen("pgrep -x yabai >/dev/null 2>&1 && echo yabai || echo aerospace")
local wm = handle:read("*l")
handle:close()

if wm == "yabai" then
	require("items.spaces_yabai")
else
	require("items.spaces_aerospace")
end
