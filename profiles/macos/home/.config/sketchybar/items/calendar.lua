local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local cal = sbar.add("item", {
  icon = {
    color = colors.primary,
    padding_left = 10,
    font = {
      style = settings.font.style_map["Bold"],
      size = 12.0,
    },
  },
  label = {
    color = colors.white,
    padding_right = 10,
    width = 78,
    align = "right",
    font = { family = settings.font.numbers },
  },
  position = "right",
  update_freq = 1,
  padding_left = 1,
  padding_right = 1,
  background = {
    color = colors.bg1,
    corner_radius = 13,
    border_width = 0,
    height = 26,
  },
  click_script = "open -a 'Calendar'"
})

-- Padding item
sbar.add("item", { position = "right", width = settings.group_paddings })

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  cal:set({ icon = os.date("%a. %d %b."), label = os.date("%H:%M:%S") })
end)
