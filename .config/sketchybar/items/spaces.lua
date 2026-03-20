local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}
local WORKSPACE_COUNT = 8

for i = 1, WORKSPACE_COUNT, 1 do
	local space = sbar.add("item", "space." .. i, {
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
	})

	spaces[i] = space

	-- Padding item
	sbar.add("item", "space.padding." .. i, {
		script = "",
		width = settings.group_paddings,
	})

	space:subscribe("mouse.clicked", function(_)
		sbar.exec("aerospace workspace " .. i)
	end)

	space:subscribe("aerospace_workspace_change", function(env)
		local focused = env.FOCUSED_WORKSPACE == tostring(i)
		space:set({
			icon = { highlight = focused },
			label = { highlight = focused },
			background = {
				color = focused and colors.primary_container or colors.transparent,
			},
		})
	end)
end

-- Update window icons in each workspace
local function update_space_windows()
	for i = 1, WORKSPACE_COUNT, 1 do
		sbar.exec(
			"aerospace list-windows --workspace " .. i .. " --format '%{app-name}' 2>/dev/null",
			function(result)
				local icon_line = ""
				local no_app = true
				for app in result:gmatch("[^\r\n]+") do
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
end

-- Refresh window icons on workspace change and window events
local space_window_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

space_window_observer:subscribe("aerospace_workspace_change", function(_)
	update_space_windows()
end)

space_window_observer:subscribe("front_app_switched", function(_)
	update_space_windows()
end)

-- Initial update
update_space_windows()

-- Trigger initial highlight for current workspace
sbar.exec("aerospace list-workspaces --focused", function(result)
	local focused = result:gsub("%s+", "")
	sbar.trigger("aerospace_workspace_change", {
		FOCUSED_WORKSPACE = focused,
	})
end)
