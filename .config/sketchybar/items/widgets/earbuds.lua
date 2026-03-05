local colors = require("colors")
local settings = require("settings")

local earbuds = sbar.add("item", "widgets.earbuds", {
  position = "right",
  icon = {
    string = "󱡏",
    font = {
      style = settings.font.style_map["Regular"],
      size = 16.0,
    },
  },
  label = { font = { family = settings.font.numbers } },
  update_freq = 120,
  updates = "on",
  drawing = false,
  popup = { align = "center" },
})

local function get_battery_color(level)
  if level > 50 then return colors.green
  elseif level > 20 then return colors.white
  else return colors.orange end
end

local function parse_earbuds_devices(output)
  local devices = {}
  local current_device = nil

  for line in output:gmatch("[^\n]+") do
    -- Device names: indented lines ending with ":" (not key-value pairs)
    local name = line:match("^%s%s%s%s+(%S.+):%s*$")
    if name
      and not name:match("%(" )
      and not name:match("Bluetooth Controller")
      and name ~= "Connected"
      and name ~= "Not Connected"
    then
      current_device = name
    end

    if current_device then
      -- "Case Battery Level (%): 65" / "Left Battery Level (%): 95"
      -- Handles both "Battery Level: 25%" and "Battery Level (%): 25"
      local side, spct = line:match("(%a+) Battery Level[^:]*:%s*(%d+)")
      if side and spct and side ~= "Case" then
        local level = tonumber(spct)
        if level and level >= 0 and level <= 100 then
          table.insert(devices, {
            name = current_device .. " (" .. side .. ")",
            level = level,
          })
        end
      else
        local pct = line:match("^%s+Battery Level[^:]*:%s*(%d+)")
        if pct then
          local level = tonumber(pct)
          if level and level >= 0 and level <= 100 then
            table.insert(devices, {
              name = current_device,
              level = level,
            })
          end
        end
      end
    end
  end

  return devices
end

local function update_earbuds()
  sbar.exec("system_profiler SPBluetoothDataType 2>/dev/null", function(output)
    local devices = parse_earbuds_devices(output)

    if #devices == 0 then
      earbuds:set({ drawing = false })
      return
    end

    -- Find lowest battery (ignore 0% as it often means not reporting)
    local min_level = nil
    for _, d in ipairs(devices) do
      if d.level > 0 then
        if not min_level or d.level < min_level then
          min_level = d.level
        end
      end
    end

    if not min_level then
      earbuds:set({ drawing = false })
      return
    end

    local color = get_battery_color(min_level)
    earbuds:set({
      drawing = true,
      icon = { string = "󱡏", color = colors.white },
      label = { string = min_level .. "%", color = color },
    })
  end)
end

earbuds:subscribe({ "routine", "forced", "system_woke" }, update_earbuds)

local popup_is_open = false

local function close_popup()
  sbar.remove('/earbuds_device\\.*/')
  earbuds:set({ popup = { drawing = false } })
  popup_is_open = false
end

earbuds:subscribe("mouse.clicked", function()
  if popup_is_open then
    close_popup()
    return
  end

  sbar.exec("system_profiler SPBluetoothDataType 2>/dev/null", function(output)
    local devices = parse_earbuds_devices(output)
    if #devices == 0 then return end

    for i, d in ipairs(devices) do
      sbar.add("item", "earbuds_device." .. i, {
        position = "popup." .. earbuds.name,
        icon = {
          string = d.name .. ":",
          width = 150,
          align = "left",
        },
        label = {
          string = d.level .. "%",
          width = 50,
          align = "right",
          color = get_battery_color(d.level),
        },
      })
    end

    earbuds:set({ popup = { drawing = true } })
    popup_is_open = true
  end)
end)

sbar.add("bracket", "widgets.earbuds.bracket", { earbuds.name }, {
  background = { color = colors.bg1 },
})

sbar.add("item", "widgets.earbuds.padding", {
  position = "right",
  width = settings.group_paddings,
})

sbar.exec("sketchybar --trigger forced")
