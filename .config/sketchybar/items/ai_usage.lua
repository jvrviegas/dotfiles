local colors = require("colors")
local settings = require("settings")

local function provider_item(name, icon, label, has_popup)
	local item = {
		position = "right",
		update_freq = 300,
		icon = {
			string = icon,
			font = "sketchybar-app-font:Regular:16.0",
			color = colors.white,
			padding_left = 4,
			padding_right = 2,
		},
		label = {
			string = label,
			font = { family = settings.font.text, style = settings.font.style_map["Bold"], size = 12.0 },
			color = colors.grey,
			padding_right = 8,
		},
		background = {
			color = colors.bg1,
			border_width = 0,
			height = 26,
			corner_radius = 13,
		},
	}

	if has_popup then
		item.popup = {
			align = "center",
			background = {
				color = colors.popup.bg,
				border_color = colors.popup.border,
				border_width = 1,
				corner_radius = 8,
			},
		}
	end

	return sbar.add("item", name, item)
end

local gpt_usage = provider_item("ai_usage.gpt", ":openai:", "?", false)
local claude_usage = provider_item("ai_usage.claude", ":claude:", "?", true)

local color_map = {
	green = colors.green,
	yellow = colors.yellow,
	red = colors.red,
	grey = colors.grey,
}

local function parse_payload(output)
	local payload = {}
	for line in output:gmatch("[^\r\n]+") do
		local key, value = line:match("^([%w_]+)=(.*)$")
		if key then
			payload[key] = value
		end
	end
	return payload
end

local function popup_row(name, icon, label, icon_color)
	return sbar.add("item", name, {
		position = "popup." .. claude_usage.name,
		icon = {
			string = icon,
			width = 92,
			align = "left",
			color = icon_color or colors.white,
			font = { family = settings.font.text, style = settings.font.style_map["Bold"], size = 12.0 },
		},
		label = {
			string = label or "?",
			width = 285,
			align = "left",
			color = colors.white,
			font = { family = settings.font.text, size = 12.0 },
		},
	})
end

local claude_header = popup_row("ai_usage.popup.claude_header", "Claude", "", colors.secondary)
local claude_5h = popup_row("ai_usage.popup.claude_5h", "5h", "?")
local claude_weekly = popup_row("ai_usage.popup.claude_weekly", "Weekly", "?")
local gpt_header = popup_row("ai_usage.popup.gpt_header", "GPT Plus", "", colors.green)
local gpt_5h = popup_row("ai_usage.popup.gpt_5h", "5h", "?")
local gpt_weekly = popup_row("ai_usage.popup.gpt_weekly", "Weekly", "?")
local updated = popup_row("ai_usage.popup.updated", "Updated", "unknown", colors.grey)
local refresh = popup_row("ai_usage.popup.refresh", "↻", "Refresh now", colors.yellow)

local function update_bar(command)
	sbar.exec(command or "$CONFIG_DIR/plugins/ai_usage.sh render", function(output)
		local payload = parse_payload(output or "")
		local claude_label = payload.CLAUDE_LABEL or "?"
		local gpt_label = payload.GPT_LABEL or "?"
		local claude_color = color_map[payload.CLAUDE_COLOR or "grey"] or colors.grey
		local gpt_color = color_map[payload.GPT_COLOR or "grey"] or colors.grey

		claude_usage:set({
			label = {
				string = claude_label,
				color = claude_color,
			},
		})
		gpt_usage:set({
			label = {
				string = gpt_label,
				color = gpt_color,
			},
		})
	end)
end

local function update_popup(command)
	sbar.exec(command or "$CONFIG_DIR/plugins/ai_usage.sh popup", function(output)
		local payload = parse_payload(output or "")
		claude_5h:set({ label = { string = payload.CLAUDE_5H or "?" } })
		claude_weekly:set({ label = { string = payload.CLAUDE_WEEKLY or "?" } })
		gpt_5h:set({ label = { string = payload.GPT_5H or "?" } })
		gpt_weekly:set({ label = { string = payload.GPT_WEEKLY or "?" } })
		updated:set({ label = { string = payload.UPDATED_AT or "unknown" } })
	end)
end

claude_usage:subscribe({ "forced", "routine", "system_woke" }, function()
	update_bar()
	update_popup()
end)

gpt_usage:subscribe({ "forced", "system_woke" }, function()
	update_bar()
	update_popup()
end)

local function toggle_popup()
	local drawing = claude_usage:query().popup.drawing
	claude_usage:set({ popup = { drawing = "toggle" } })
	if drawing == "off" then
		update_popup()
	end
end

claude_usage:subscribe("mouse.clicked", toggle_popup)
gpt_usage:subscribe("mouse.clicked", toggle_popup)

refresh:subscribe("mouse.clicked", function()
	refresh:set({
		icon = { string = "…", color = colors.yellow },
		label = { string = "Refreshing..." },
	})

	sbar.exec("$CONFIG_DIR/plugins/ai_usage.sh refresh", function()
		update_bar()
		update_popup()
		refresh:set({
			icon = { string = "✓", color = colors.green },
			label = { string = "Refreshed " .. os.date("%H:%M:%S") },
		})
		sbar.exec("sleep 2", function()
			refresh:set({
				icon = { string = "↻", color = colors.yellow },
				label = { string = "Refresh now" },
			})
		end)
	end)

	-- Failsafe: never leave the UI stuck if a subprocess hangs unexpectedly.
	sbar.exec("sleep 15", function()
		refresh:set({
			icon = { string = "↻", color = colors.yellow },
			label = { string = "Refresh now" },
		})
	end)
end)

sbar.add("item", "ai_usage.padding", {
	position = "right",
	width = settings.group_paddings,
})
