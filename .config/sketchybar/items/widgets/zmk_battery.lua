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
  label = { drawing = false, font = { family = settings.font.numbers } },
  updates = true,
  update_freq = 30,
  popup = { align = "center" },
})

local popup_status = sbar.add("item", "zmk_battery_detail.status", {
  position = "popup." .. zmk_battery.name,
  icon = {
    string = "Keyboard:",
    width = 120,
    align = "left",
  },
  label = {
    string = "—",
    width = 80,
    align = "right",
  },
})

local popup_left = sbar.add("item", "zmk_battery_detail.left", {
  position = "popup." .. zmk_battery.name,
  drawing = false,
  icon = {
    string = "Left:",
    width = 120,
    align = "left",
  },
  label = {
    string = "—",
    width = 80,
    align = "right",
  },
})

local popup_right = sbar.add("item", "zmk_battery_detail.right", {
  position = "popup." .. zmk_battery.name,
  drawing = false,
  icon = {
    string = "Right:",
    width = 120,
    align = "left",
  },
  label = {
    string = "—",
    width = 80,
    align = "right",
  },
})

local popup_refresh = sbar.add("item", "zmk_battery_detail.refresh", {
  position = "popup." .. zmk_battery.name,
  icon = {
    string = "↻",
    color = colors.yellow,
    width = 120,
    align = "left",
  },
  label = {
    string = "Refresh now",
    width = 80,
    align = "right",
    color = colors.yellow,
  },
})

local function get_battery_color(charge)
  charge = math.max(0, math.min(100, charge or 0))

  if charge <= 10 then
    return colors.red
  elseif charge <= 20 then
    return colors.orange
  elseif charge <= 50 then
    return colors.yellow
  end

  return colors.green
end

local function min_level(levels)
  local min = levels[1]
  for _, level in ipairs(levels) do
    if level < min then min = level end
  end
  return min
end

local zmk_device_name = "Keyboard"
local zmk_is_connected = false

local function find_zmk_name(callback)
  sbar.exec("system_profiler SPBluetoothDataType 2>/dev/null", function(output)
    local current_name = nil
    local current_section = nil
    for line in output:gmatch("[^\n]+") do
      local section = line:match("^%s+(Connected):%s*$") or line:match("^%s+(Not Connected):%s*$")
      if section then
        current_section = section
      end

      local name = line:match("^%s%s%s%s+(%S.+):%s*$")
      if name and not name:match("%(") and name ~= "Connected" and name ~= "Not Connected" then
        current_name = name
      end
      if current_name and line:match("Vendor ID:%s*0x1D50") then
        zmk_device_name = current_name
        zmk_is_connected = current_section == "Connected"
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

  local labels_str = attr:match('"labels"%s*:%s*%[([^%]]*)%]')
  local labels = {}
  if labels_str then
    for label in labels_str:gmatch('"([^"]+)"') do
      table.insert(labels, label)
    end
  end

  return connected, levels, labels
end

local function update_battery()
  local connected, levels = read_battery_state()

  connected = connected and zmk_is_connected

  if connected and #levels > 0 then
    local color = get_battery_color(min_level(levels))
    zmk_battery:set({
      drawing = true,
      icon = { string = "󰌌", color = color },
      label = { drawing = false },
    })
  elseif connected then
    zmk_battery:set({
      drawing = true,
      icon = { string = "󰌌", color = colors.grey },
      label = { drawing = false },
    })
  else
    zmk_battery:set({ drawing = false })
  end
end

zmk_battery:subscribe({"routine", "system_woke"}, function()
  find_zmk_name(update_battery)
end)

local function update_popup_details()
  local connected, levels, labels = read_battery_state()
  connected = connected and zmk_is_connected
  popup_status:set({
    icon = { string = zmk_device_name .. ":" },
    label = { string = connected and "Connected" or "Disconnected", color = connected and colors.white or colors.grey },
  })

  if connected and #levels >= 2 then
    popup_left:set({
      drawing = true,
      icon = { string = (labels[1] or "Left") .. ":" },
      label = { string = levels[1] .. "%", color = get_battery_color(levels[1]) },
    })
    popup_right:set({
      drawing = true,
      icon = { string = (labels[2] or "Right") .. ":" },
      label = { string = levels[2] .. "%", color = get_battery_color(levels[2]) },
    })
  elseif connected and #levels == 1 then
    popup_left:set({
      drawing = true,
      icon = { string = (labels[1] or "Battery") .. ":" },
      label = { string = levels[1] .. "%", color = get_battery_color(levels[1]) },
    })
    popup_right:set({ drawing = false })
  else
    popup_left:set({ drawing = false })
    popup_right:set({ drawing = false })
  end
end

local function reset_refresh_button()
  popup_refresh:set({
    icon = { string = "↻", color = colors.yellow },
    label = { string = "Refresh now", color = colors.yellow },
  })
end

local popup_is_open = false

zmk_battery:subscribe("mouse.clicked", function(env)
  if not popup_is_open then
    find_zmk_name(update_popup_details)
  end
  popup_is_open = not popup_is_open
  zmk_battery:set({ popup = { drawing = "toggle" } })
end)

popup_refresh:subscribe("mouse.clicked", function(env)
  popup_refresh:set({
    icon = { string = "…", color = colors.yellow },
    label = { string = "Refreshing...", color = colors.yellow },
  })

  sbar.exec("launchctl kickstart -k gui/$(id -u)/com.zmk.batterydaemon; sleep 1", function()
    find_zmk_name(function()
      update_battery()
      update_popup_details()
      popup_refresh:set({
        icon = { string = "✓", color = colors.green },
        label = { string = "Refreshed " .. os.date("%H:%M:%S"), color = colors.green },
      })
      sbar.exec("sleep 2", reset_refresh_button)
    end)
  end)

  sbar.exec("sleep 10", reset_refresh_button)
end)

sbar.add("bracket", "widgets.zmk_battery.bracket", { zmk_battery.name }, {
  background = { color = colors.bg1, corner_radius = 13 },
})

sbar.add("item", "widgets.zmk_battery.padding", {
  position = "right",
  width = settings.group_paddings,
})

find_zmk_name(update_battery)
