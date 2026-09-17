local colors = require("colors")
local icons = require("icons")
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

local ai_settings = sbar.add("item", "ai_usage.settings", {
	position = "right",
	drawing = true,
	icon = {
		string = icons.gear,
		font = { family = settings.font.text, style = settings.font.style_map["Bold"], size = 16.0 },
		color = colors.secondary,
		padding_left = 6,
		padding_right = 6,
	},
	label = { drawing = false },
	background = {
		color = colors.bg1,
		border_width = 0,
		height = 26,
		corner_radius = 13,
	},
	popup = {
		align = "center",
		background = {
			color = colors.popup.bg,
			border_color = colors.popup.border,
			border_width = 1,
			corner_radius = 8,
		},
	},
})

local gpt_usage = provider_item("ai_usage.gpt", ":openai:", "?", true)
local claude_usage = provider_item("ai_usage.claude", ":claude:", "?", true)
local deepseek_usage = provider_item("ai_usage.deepseek", ":deepseek:", "?", false)

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

local function popup_row(name, icon, label, icon_color, parent)
	parent = parent or claude_usage
	return sbar.add("item", name, {
		position = "popup." .. parent.name,
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
local claude_fable = popup_row("ai_usage.popup.claude_fable", "Fable wk", "?")
local gpt_header = popup_row("ai_usage.popup.gpt_header", "GPT/Codex", "", colors.green)
local gpt_5h = popup_row("ai_usage.popup.gpt_5h", "5h", "?")
local gpt_weekly = popup_row("ai_usage.popup.gpt_weekly", "Weekly", "?")
local gpt_credits = popup_row("ai_usage.popup.gpt_credits", "Credits", "?")
local deepseek_header = popup_row("ai_usage.popup.deepseek_header", "DeepSeek", "", colors.blue)
local deepseek_balance = popup_row("ai_usage.popup.deepseek_balance", "Balance", "?")
local updated = popup_row("ai_usage.popup.updated", "Updated", "unknown", colors.grey)
local refresh = popup_row("ai_usage.popup.refresh", "↻", "Refresh now", colors.yellow)

local claude_visibility = popup_row("ai_usage.settings.claude", "Claude", "Visible", colors.secondary, ai_settings)
local gpt_visibility = popup_row("ai_usage.settings.gpt", "GPT/Codex", "Visible", colors.green, ai_settings)
local deepseek_visibility = popup_row("ai_usage.settings.deepseek", "DeepSeek", "Visible", colors.blue, ai_settings)

local provider_items = {
	claude = claude_usage,
	gpt = gpt_usage,
	deepseek = deepseek_usage,
}

local visibility_rows = {
	claude = claude_visibility,
	gpt = gpt_visibility,
	deepseek = deepseek_visibility,
}

local visibility_prefixes = {
	claude = "CLAUDE",
	gpt = "GPT",
	deepseek = "DEEPSEEK",
}

local function update_bar(command)
	sbar.exec(command or "$CONFIG_DIR/plugins/ai_usage.sh render", function(output)
		local payload = parse_payload(output or "")
		local claude_label = payload.CLAUDE_LABEL or "?"
		local gpt_label = payload.GPT_LABEL or "?"
		local deepseek_label = payload.DEEPSEEK_LABEL or "?"
		local claude_color = color_map[payload.CLAUDE_COLOR or "grey"] or colors.grey
		local gpt_color = color_map[payload.GPT_COLOR or "grey"] or colors.grey
		local deepseek_color = color_map[payload.DEEPSEEK_COLOR or "grey"] or colors.grey

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
		deepseek_usage:set({
			label = {
				string = deepseek_label,
				color = deepseek_color,
			},
		})
	end)
end

local function popup_header_label(provider, plan)
	if plan and plan ~= "" then
		return provider .. " · " .. plan
	end
	return provider
end

local function update_popup(command)
	sbar.exec(command or "$CONFIG_DIR/plugins/ai_usage.sh popup", function(output)
		local payload = parse_payload(output or "")
		claude_header:set({ label = { string = popup_header_label("Claude", payload.CLAUDE_PLAN) } })
		gpt_header:set({ label = { string = popup_header_label("GPT/Codex", payload.GPT_PLAN) } })
		claude_5h:set({ label = { string = payload.CLAUDE_5H or "?" } })
		claude_weekly:set({ label = { string = payload.CLAUDE_WEEKLY or "?" } })
		claude_fable:set({ label = { string = payload.CLAUDE_FABLE or "?" } })
		gpt_5h:set({ label = { string = payload.GPT_5H or "?" } })
		gpt_weekly:set({ label = { string = payload.GPT_WEEKLY or "?" } })
		gpt_credits:set({ label = { string = payload.GPT_CREDITS or "?" } })
		deepseek_balance:set({ label = { string = payload.DEEPSEEK_BALANCE or "?" } })
		updated:set({ label = { string = payload.UPDATED_AT or "unknown" } })
	end)
end

local function set_visibility(provider, visible)
	provider_items[provider]:set({ drawing = visible })
	visibility_rows[provider]:set({
		label = {
			string = visible and "Visible" or "Hidden",
			color = visible and colors.green or colors.grey,
		},
	})
end

local function apply_visibility(output, only_provider)
	local payload = parse_payload(output or "")
	if only_provider then
		local prefix = visibility_prefixes[only_provider]
		local value = payload[prefix .. "_VISIBLE"]
		if value then
			-- The helper normalizes invalid values to true; do the same if it fails.
			set_visibility(only_provider, value ~= "false")
		end
		return
	end

	for provider, prefix in pairs(visibility_prefixes) do
		-- The helper normalizes invalid values to true; do the same if it fails.
		set_visibility(provider, payload[prefix .. "_VISIBLE"] ~= "false")
	end
end

local function update_visibility(command)
	sbar.exec(command or "$CONFIG_DIR/plugins/ai_usage_visibility.sh get", function(output)
		apply_visibility(output)
	end)
end

local function toggle_visibility(provider)
	sbar.exec("$CONFIG_DIR/plugins/ai_usage_visibility.sh toggle " .. provider, function(output)
		apply_visibility(output, provider)
	end)
end

claude_usage:subscribe({ "forced", "routine", "system_woke" }, function()
	update_bar()
	update_popup()
end)

gpt_usage:subscribe({ "forced", "routine", "system_woke" }, function()
	update_bar()
	update_popup()
end)

deepseek_usage:subscribe({ "forced", "routine", "system_woke" }, function()
	update_bar()
	update_popup()
end)

-- The detail rows are shared and are children of Claude's popup.  Other
-- provider items must therefore toggle that populated popup rather than their
-- own (empty or absent) popup containers.
local function toggle_popup()
	local drawing = claude_usage:query().popup.drawing
	claude_usage:set({ popup = { drawing = "toggle" } })
	if drawing == "off" then
		update_popup()
	end
end

local function toggle_settings_popup()
	local drawing = ai_settings:query().popup.drawing
	ai_settings:set({ popup = { drawing = "toggle" } })
	if drawing == "off" then
		update_visibility()
	end
end

claude_visibility:subscribe("mouse.clicked", function() toggle_visibility("claude") end)
gpt_visibility:subscribe("mouse.clicked", function() toggle_visibility("gpt") end)
deepseek_visibility:subscribe("mouse.clicked", function() toggle_visibility("deepseek") end)
ai_settings:subscribe("mouse.clicked", toggle_settings_popup)

claude_usage:subscribe("mouse.clicked", toggle_popup)
gpt_usage:subscribe("mouse.clicked", toggle_popup)
deepseek_usage:subscribe("mouse.clicked", toggle_popup)

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

update_visibility()

sbar.add("item", "ai_usage.padding", {
	position = "right",
	width = settings.group_paddings,
})
