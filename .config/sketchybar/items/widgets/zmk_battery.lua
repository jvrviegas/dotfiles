local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local json_file = os.getenv("HOME") .. "/.local/state/zmk-battery/battery.json"

local zmk_battery = sbar.add("item", "widgets.zmk_battery", {
  position = "right",
  icon = {
    font = {
      style = settings.font.style_map["Semibold"],
      size = 18.0,
    },
  },
  label = { font = { family = settings.font.numbers } },
  update_freq = 30,
  popup = { align = "center" },
})

local popup_info = sbar.add("item", {
  position = "popup." .. zmk_battery.name,
  icon = {
    string = "Totem:",
    width = 100,
    align = "left",
  },
  label = {
    string = "—",
    width = 100,
    align = "right",
  },
})

local function get_battery_color(charge)
  if charge > 50 then return colors.green
  elseif charge > 20 then return colors.white
  else return colors.orange end
end

local zmk_device_name = "Keyboard"

local function find_zmk_name(callback)
  sbar.exec("system_profiler SPBluetoothDataType 2>/dev/null", function(output)
    local current_name = nil
    for line in output:gmatch("[^\n]+") do
      local name = line:match("^%s%s%s%s+(%S.+):%s*$")
      if name and not name:match("%(") and name ~= "Connected" and name ~= "Not Connected" then
        current_name = name
      end
      if current_name and line:match("Vendor ID:%s*0x1D50") then
        zmk_device_name = current_name
        break
      end
    end
    if callback then callback() end
  end)
end

local function read_battery_state()
  local f = io.open(json_file, "r")
  if not f then return false, {} end

  local attr = f:read("*a")
  f:close()

  local ts_str = attr:match('"timestamp"%s*:%s*(%d+)')
  local ts = tonumber(ts_str) or 0
  if (os.time() - ts) > 300 then
    return false, {}
  end

  local connected = attr:match('"connected"%s*:%s*(%a+)') == "true"
  local levels_str = attr:match('"levels"%s*:%s*%[([%d%s,]*)%]')
  local levels = {}
  if levels_str then
    for num in levels_str:gmatch("%d+") do
      table.insert(levels, tonumber(num))
    end
  end

  return connected, levels
end

local function update_battery()
  local connected, levels = read_battery_state()

  if connected and #levels > 0 then
    local min_level = levels[1]
    for _, l in ipairs(levels) do
      if l < min_level then min_level = l end
    end
    local color = get_battery_color(min_level)
    zmk_battery:set({
      icon = { string = "󰌌", color = colors.white },
      label = { string = min_level .. "%", color = color },
    })
  else
    zmk_battery:set({
      icon = { string = "󰌌", color = colors.grey },
      label = { string = "—", color = colors.grey },
    })
  end
end

zmk_battery:subscribe({"routine", "system_woke"}, function()
  find_zmk_name(update_battery)
end)

local popup_is_open = false

zmk_battery:subscribe("mouse.clicked", function(env)
  if not popup_is_open then
    local connected, levels = read_battery_state()
    if connected and #levels > 0 then
      local parts = {}
      for _, level in ipairs(levels) do
        table.insert(parts, level .. "%")
      end
      popup_info:set({
        icon = { string = zmk_device_name .. ":" },
        label = { string = table.concat(parts, "  ") },
      })
    else
      popup_info:set({
        icon = { string = zmk_device_name .. ":" },
        label = { string = "Disconnected" },
      })
    end
  end
  popup_is_open = not popup_is_open
  zmk_battery:set({ popup = { drawing = "toggle" } })
end)

sbar.add("bracket", "widgets.zmk_battery.bracket", { zmk_battery.name }, {
  background = { color = colors.bg1, corner_radius = 13 },
})

sbar.add("item", "widgets.zmk_battery.padding", {
  position = "right",
  width = settings.group_paddings,
})

find_zmk_name(update_battery)
