local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Padding item required because of bracket
sbar.add("item", { width = 5 })

local apple = sbar.add("item", {
  icon = {
    font = { size = 16.0 },
    string = icons.apple,
    padding_right = 8,
    padding_left = 8,
    color = colors.primary,
  },
  label = { drawing = false },
  background = {
    color = colors.primary_container,
    corner_radius = 13,
    border_width = 0,
    height = 26,
  },
  padding_left = 1,
  padding_right = 1,
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0"
})

-- Padding item
sbar.add("item", { width = 5 })
