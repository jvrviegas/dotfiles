-- Load theme from ~/.config/theme/current (synced with theme-switch)
local theme_name = "the-mandalorian"

local f = io.open(os.getenv("HOME") .. "/.config/theme/current", "r")
if f then
	local name = f:read("*l")
	f:close()
	if name and name ~= "" then
		theme_name = name:gsub("%s+", "")
	end
end

local ok, theme = pcall(require, "themes." .. theme_name)
if not ok then
	theme = require("themes.the-mandalorian")
end

theme.transparent = 0x00000000

theme.with_alpha = function(color, alpha)
	if alpha > 1.0 or alpha < 0.0 then
		return color
	end
	return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

return theme
