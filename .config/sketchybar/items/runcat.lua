-- Define the cat frames for animation
local frames = { "🐱", "🐈", "🐆", "🐅" }
local frame_index = 1

-- Add the item to SketchyBar
local runcat = sbar.add("item", "runcat", {
	position = "right",
	label = {
		text = frames[frame_index],
		font = "Hack Nerd Font:Bold:12.0",
		color = 0xfff5c2e7,
		padding_right = 10,
	},
	click_script = "open -a 'Activity Monitor'",
})

-- Function to get CPU usage
local function get_cpu_usage()
	local handle = io.popen("ps -A -o %cpu | awk '{s+=$1} END {print s}'")
	local result = handle:read("*a")
	handle:close()
	return tonumber(result) or 0
end

-- Timer to animate the cat
local function update_runcat()
	local cpu = get_cpu_usage()

	-- Update the cat frame
	runcat:set({
		label = {
			text = frames[frame_index] .. " " .. string.format("%.0f", cpu) .. "%",
		},
	})

	frame_index = frame_index % #frames + 1
end

-- Set up timer with fixed interval
sbar.timer(0.5, update_runcat)
