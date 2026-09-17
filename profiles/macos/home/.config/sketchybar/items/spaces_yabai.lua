local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}
local WORKSPACE_COUNT = 8

for i = 1, WORKSPACE_COUNT, 1 do
	local space = sbar.add("space", "space." .. i, {
		associated_space = i,
		icon = {
			font = { family = settings.font.numbers },
			string = i,
			padding_left = 10,
			padding_right = 8,
			color = colors.grey,
			highlight_color = colors.primary,
		},
		label = {
			padding_right = 12,
			color = colors.grey,
			highlight_color = colors.primary,
			font = "sketchybar-app-font:Regular:16.0",
			y_offset = -1,
		},
		padding_right = 1,
		padding_left = 1,
		background = {
			color = colors.transparent,
			corner_radius = 13,
			border_width = 0,
			height = 26,
		},
		click_script = "yabai -m space --focus " .. i,
	})

	spaces[i] = space

	-- Padding item
	sbar.add("item", "space.padding." .. i, {
		script = "",
		width = settings.group_paddings,
	})

	space:subscribe("space_change", function(env)
		local selected = env.SELECTED == "true"
		space:set({
			icon = { highlight = selected },
			label = { highlight = selected },
			background = {
				color = selected and colors.primary_container or colors.transparent,
			},
		})
	end)
end

-- Update window icons per space
local space_window_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

space_window_observer:subscribe("space_windows_change", function(env)
	local icon_line = ""
	local no_app = true
	for app, _ in pairs(env.INFO.apps) do
		no_app = false
		local lookup = app_icons[app]
		local icon = ((lookup == nil) and app_icons["Default"] or lookup)
		icon_line = icon_line .. icon
	end

	if no_app then
		icon_line = " —"
	end
	sbar.animate("tanh", 10, function()
		spaces[env.INFO.space]:set({ label = icon_line })
	end)
end)

space_window_observer:subscribe("front_app_switched", function(_)
	for i = 1, WORKSPACE_COUNT, 1 do
		sbar.exec(
			"yabai -m query --windows --space " .. i .. " 2>/dev/null",
			function(result)
				local icon_line = ""
				local no_app = true
				for app in result:gmatch('"app"%s*:%s*"([^"]+)"') do
					no_app = false
					local lookup = app_icons[app]
					local icon = ((lookup == nil) and app_icons["Default"] or lookup)
					icon_line = icon_line .. icon
				end
				if no_app then
					icon_line = " —"
				end
				spaces[i]:set({ label = icon_line })
			end
		)
	end
end)
